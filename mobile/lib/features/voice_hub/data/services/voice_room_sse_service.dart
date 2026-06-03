import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../../../../core/network/api_endpoints.dart';
import '../../domain/entities/chat_room_message.dart';
import '../../domain/entities/chat_room_presence.dart';
import 'voice_room_debug_log.dart';

/// GET `/api/chat/rooms/{id}/stream` — Server-Sent Events (opsiyonel).
class VoiceRoomSseService {
  VoiceRoomSseService(this._dio);

  final Dio _dio;
  CancelToken? _cancel;
  StreamSubscription<List<int>>? _bytesSub;

  void Function(ChatRoomMessage message)? _onMessage;
  void Function(List<ChatRoomPresence> users)? _onPresence;

  Future<void> connect({
    required String roomId,
    required Future<String?> Function() accessToken,
    void Function(ChatRoomMessage message)? onMessage,
    void Function(List<ChatRoomPresence> users)? onPresence,
  }) async {
    await disconnect();
    final id = roomId.trim();
    if (id.isEmpty) return;
    _onMessage = onMessage;
    _onPresence = onPresence;

    final token = await accessToken();
    if (token == null || token.trim().isEmpty) {
      VoiceRoomDebugLog.log('sse.skip', {'reason': 'no_token'});
      return;
    }

    _cancel = CancelToken();
    try {
      VoiceRoomDebugLog.log('sse.connecting', {'roomId': id});
      final res = await _dio.get<ResponseBody>(
        ApiEndpoints.chatRoomStream(id),
        options: Options(
          responseType: ResponseType.stream,
          headers: {
            'Authorization': 'Bearer ${token.trim()}',
            'Accept': 'text/event-stream',
            'Cache-Control': 'no-cache',
          },
        ),
        cancelToken: _cancel,
      );
      final stream = res.data?.stream;
      if (stream == null) return;

      final buffer = StringBuffer();
      _bytesSub = stream.listen(
        (chunk) {
          buffer.write(utf8.decode(chunk, allowMalformed: true));
          _drainSseBuffer(buffer);
        },
        onError: (Object e) {
          VoiceRoomDebugLog.log('sse.error', {'error': e.toString()});
        },
        onDone: () => VoiceRoomDebugLog.log('sse.done'),
        cancelOnError: false,
      );
      VoiceRoomDebugLog.log('sse.connected');
    } catch (e) {
      VoiceRoomDebugLog.log('sse.fail', {'error': e.toString()});
      if (kDebugMode) debugPrint('Voice room SSE: $e');
    }
  }

  void _drainSseBuffer(StringBuffer buffer) {
    var raw = buffer.toString();
    while (true) {
      final sep = raw.indexOf('\n\n');
      if (sep < 0) break;
      final block = raw.substring(0, sep);
      raw = raw.substring(sep + 2);
      _handleSseBlock(block);
    }
    buffer
      ..clear()
      ..write(raw);
  }

  void _handleSseBlock(String block) {
    final dataLines = <String>[];
    for (final line in block.split('\n')) {
      if (line.startsWith('data:')) {
        dataLines.add(line.substring(5).trimLeft());
      }
    }
    if (dataLines.isEmpty) return;
    final payload = dataLines.join('\n').trim();
    if (payload.isEmpty || payload == '[DONE]') return;
    try {
      final decoded = jsonDecode(payload);
      if (decoded is! Map) return;
      final map = Map<String, dynamic>.from(decoded);
      _dispatchPayload(map);
    } catch (_) {}
  }

  void _dispatchPayload(Map<String, dynamic> map) {
    if (map['message'] is Map) {
      final msg = ChatRoomMessage.fromJson(
        Map<String, dynamic>.from(map['message'] as Map),
      );
      if (msg.content.isNotEmpty) _onMessage?.call(msg);
      return;
    }
    if (map['content'] != null && map['id'] != null) {
      final msg = ChatRoomMessage.fromJson(map);
      if (msg.content.isNotEmpty) _onMessage?.call(msg);
      return;
    }
    final usersRaw =
        map['users'] ?? map['presence'] ?? map['members'] ?? map['data'];
    if (usersRaw is List) {
      final users = usersRaw
          .whereType<Map>()
          .map((e) => ChatRoomPresence.fromJson(Map<String, dynamic>.from(e)))
          .where((u) => u.id.isNotEmpty)
          .toList();
      if (users.isNotEmpty) _onPresence?.call(users);
    }
  }

  Future<void> disconnect() async {
    _cancel?.cancel('disconnect');
    _cancel = null;
    await _bytesSub?.cancel();
    _bytesSub = null;
    _onMessage = null;
    _onPresence = null;
  }
}
