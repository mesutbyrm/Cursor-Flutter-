import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../../../../core/config/env.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../domain/entities/chat_room_message.dart';
import '../../domain/entities/chat_room_presence.dart';
import '../../domain/entities/voice_room_sse_event.dart';
import 'voice_room_debug_log.dart';

/// Birincil gerçek zamanlı kanal — `GET /api/chat/rooms/{room.id}/stream` (SSE).
///
/// Socket.IO kullanılmaz. Dio akışı için ayrı istemci (receiveTimeout yok).
class VoiceRoomSseService {
  VoiceRoomSseService();

  static Dio _sseDio() {
    return Dio(
      BaseOptions(
        baseUrl: Env.apiBaseUrl,
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: Duration.zero,
        headers: {'Accept': 'text/event-stream'},
      ),
    );
  }

  Dio? _dio;
  CancelToken? _cancel;
  StreamSubscription<List<int>>? _bytesSub;
  Timer? _reconnectTimer;

  String? _roomId;
  Future<String?> Function()? _accessToken;
  var _stopped = false;
  var _reconnectAttempt = 0;

  void Function()? _onConnected;
  void Function(ChatRoomMessage message)? _onMessage;
  void Function(List<ChatRoomPresence> users)? _onPresence;
  void Function(Map<String, dynamic> payload)? _onDjUpdate;

  /// Tam URL — log / teşhis için.
  static String streamUrlFor(String roomId) {
    final base = Env.apiBaseUrl.replaceAll(RegExp(r'/$'), '');
    return '$base${ApiEndpoints.chatRoomStream(roomId.trim())}';
  }

  Future<void> connect({
    required String roomId,
    required Future<String?> Function() accessToken,
    void Function()? onConnected,
    void Function(ChatRoomMessage message)? onMessage,
    void Function(List<ChatRoomPresence> users)? onPresence,
    void Function(Map<String, dynamic> payload)? onDjUpdate,
  }) async {
    _stopped = false;
    _roomId = roomId.trim();
    _accessToken = accessToken;
    _onConnected = onConnected;
    _onMessage = onMessage;
    _onPresence = onPresence;
    _onDjUpdate = onDjUpdate;
    await _openStream();
  }

  Future<void> _openStream() async {
    await _closeStreamOnly();
    final id = _roomId;
    if (id == null || id.isEmpty || _stopped) return;

    final token = _accessToken != null ? await _accessToken!() : null;
    final headers = <String, dynamic>{
      'Accept': 'text/event-stream',
      'Cache-Control': 'no-cache',
    };
    if (token != null && token.trim().isNotEmpty) {
      headers['Authorization'] = 'Bearer ${token.trim()}';
    }

    final url = streamUrlFor(id);
    VoiceRoomDebugLog.log('sse.connecting', {
      'url': url,
      'hasToken': token != null && token.isNotEmpty,
    });

    _dio = _sseDio();
    _cancel = CancelToken();
    try {
      final res = await _dio!.get<ResponseBody>(
        ApiEndpoints.chatRoomStream(id),
        options: Options(
          responseType: ResponseType.stream,
          headers: headers,
        ),
        cancelToken: _cancel,
      );
      final byteStream = res.data?.stream;
      if (byteStream == null) {
        VoiceRoomDebugLog.log('sse.fail', {'reason': 'empty_stream'});
        _scheduleReconnect();
        return;
      }

      _reconnectAttempt = 0;
      final buffer = StringBuffer();
      _bytesSub = byteStream.listen(
        (chunk) {
          buffer.write(utf8.decode(chunk, allowMalformed: true));
          _drainSseBuffer(buffer);
        },
        onError: (Object e) {
          VoiceRoomDebugLog.log('sse.error', {'error': e.toString()});
          _scheduleReconnect();
        },
        onDone: () {
          VoiceRoomDebugLog.log('sse.done');
          _scheduleReconnect();
        },
        cancelOnError: false,
      );
      VoiceRoomDebugLog.log('sse.stream_open', {'url': url});
    } catch (e) {
      VoiceRoomDebugLog.log('sse.fail', {'error': e.toString(), 'url': url});
      if (kDebugMode) debugPrint('Voice room SSE: $e');
      _scheduleReconnect();
    }
  }

  void _scheduleReconnect() {
    if (_stopped || _roomId == null) return;
    _reconnectTimer?.cancel();
    _reconnectAttempt++;
    final delay = Duration(
      seconds: (_reconnectAttempt.clamp(1, 6) * 2),
    );
    VoiceRoomDebugLog.log('sse.reconnect_scheduled', {
      'attempt': _reconnectAttempt,
      'delaySec': delay.inSeconds,
    });
    _reconnectTimer = Timer(delay, () {
      if (!_stopped) unawaited(_openStream());
    });
  }

  void _drainSseBuffer(StringBuffer buffer) {
    var raw = buffer.toString().replaceAll('\r\n', '\n');
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
    String? eventName;
    final dataLines = <String>[];
    for (final line in block.split('\n')) {
      if (line.startsWith('event:')) {
        eventName = line.substring(6).trim();
      } else if (line.startsWith('data:')) {
        dataLines.add(line.substring(5).trimLeft());
      }
    }
    if (dataLines.isEmpty) return;
    final payload = dataLines.join('\n').trim();
    if (payload.isEmpty || payload == '[DONE]') return;

    VoiceRoomDebugLog.log('sse.payload', {
      'event': eventName ?? '',
      'bytes': payload.length,
      'preview': payload.length > 120 ? '${payload.substring(0, 120)}…' : payload,
    });

    try {
      final decoded = jsonDecode(payload);
      if (decoded is! Map) return;
      final map = Map<String, dynamic>.from(decoded);
      _dispatch(map, eventName);
    } catch (e) {
      VoiceRoomDebugLog.log('sse.parse_fail', {'error': e.toString()});
    }
  }

  void _dispatch(Map<String, dynamic> map, String? sseEventName) {
    final typeRaw = map['type']?.toString() ?? sseEventName ?? '';
    final kind = voiceRoomSseKindFrom(typeRaw);

    switch (kind) {
      case VoiceRoomSseKind.connected:
        VoiceRoomDebugLog.log('sse.connected', {
          'roomId': map['roomId']?.toString() ?? '',
        });
        _onConnected?.call();
        return;
      case VoiceRoomSseKind.typing:
        return;
      case VoiceRoomSseKind.presence:
      case VoiceRoomSseKind.userJoined:
      case VoiceRoomSseKind.userLeft:
        final users = _parseUsers(map);
        if (users != null) {
          VoiceRoomDebugLog.log('sse.presence', {
            'type': typeRaw,
            'count': users.length,
          });
          _onPresence?.call(users);
        }
        return;
      case VoiceRoomSseKind.message:
        final msg = _parseMessage(map);
        if (msg != null) {
          VoiceRoomDebugLog.log('sse.message', {'id': msg.id});
          _onMessage?.call(msg);
        }
        return;
      case VoiceRoomSseKind.gift:
        return;
      case VoiceRoomSseKind.dj:
        VoiceRoomDebugLog.log('sse.dj', {'room': _roomId});
        _onDjUpdate?.call(map);
        return;
      case VoiceRoomSseKind.unknown:
        if (map.containsKey('musicUrl') || map.containsKey('playing')) {
          VoiceRoomDebugLog.log('sse.dj', {'room': _roomId});
          _onDjUpdate?.call(map);
          return;
        }
        if (_tryPresence(map)) return;
        final msg = _parseMessage(map);
        if (msg != null) _onMessage?.call(msg);
    }
  }

  bool _tryPresence(Map<String, dynamic> map) {
    final users = _parseUsers(map);
    if (users == null || users.isEmpty) return false;
    _onPresence?.call(users);
    return true;
  }

  List<ChatRoomPresence>? _parseUsers(Map<String, dynamic> map) {
    dynamic raw = map['users'] ?? map['presence'] ?? map['members'];
    if (raw == null && map['user'] is Map) raw = [map['user']];
    if (raw is! List) return null;
    final users = raw
        .whereType<Map>()
        .map((e) => ChatRoomPresence.fromJson(Map<String, dynamic>.from(e)))
        .where((u) => u.id.isNotEmpty)
        .toList();
    return users;
  }

  ChatRoomMessage? _parseMessage(Map<String, dynamic> map) {
    Map<String, dynamic>? msgMap;
    if (map['message'] is Map) {
      msgMap = Map<String, dynamic>.from(map['message'] as Map);
    } else if (map['content'] != null) {
      msgMap = map;
    }
    if (msgMap == null) return null;
    final msg = ChatRoomMessage.fromJson(msgMap);
    return msg.content.isNotEmpty ? msg : null;
  }

  Future<void> _closeStreamOnly() async {
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
    _cancel?.cancel('reconnect');
    _cancel = null;
    await _bytesSub?.cancel();
    _bytesSub = null;
    _dio?.close(force: true);
    _dio = null;
  }

  Future<void> disconnect() async {
    _stopped = true;
    _roomId = null;
    _accessToken = null;
    _onConnected = null;
    _onMessage = null;
    _onDjUpdate = null;
    _onPresence = null;
    await _closeStreamOnly();
    VoiceRoomDebugLog.log('sse.disconnect');
  }
}
