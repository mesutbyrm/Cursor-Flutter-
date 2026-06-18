import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../../../../core/config/env.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../domain/entities/chat_room_message.dart';
import '../../domain/entities/chat_room_presence.dart';
import '../../domain/entities/chat_room_sse_event.dart';
import 'voice_room_debug_log.dart';

/// Sohbet odası SSE — `GET /api/chat/rooms/{roomId}/stream`.
///
/// Dio stream ile SSE ayrıştırma (`eventsource` paketi `http` sürümü
/// `youtube_explode_dart` ile çakıştığı için kullanılmıyor).
class ChatRoomSseService {
  ChatRoomSseService();

  final _events = StreamController<ChatRoomSseEvent>.broadcast();
  Stream<ChatRoomSseEvent> get events => _events.stream;

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
  void Function(Map<String, dynamic> payload)? _onSong;
  void Function(Map<String, dynamic> payload)? _onGift;
  void Function(Map<String, dynamic> payload)? _onRoomUpdate;
  void Function(Map<String, dynamic> payload)? _onModeration;
  void Function(Map<String, dynamic> payload)? _onAnnouncement;
  void Function(Map<String, dynamic> payload)? _onFortuneRequest;
  void Function(List<String> users)? _onTyping;

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
    void Function(Map<String, dynamic> payload)? onSong,
    void Function(Map<String, dynamic> payload)? onGift,
    void Function(Map<String, dynamic> payload)? onRoomUpdate,
    void Function(Map<String, dynamic> payload)? onModeration,
    void Function(Map<String, dynamic> payload)? onAnnouncement,
    void Function(Map<String, dynamic> payload)? onFortuneRequest,
    void Function(List<String> users)? onTyping,
  }) async {
    final id = roomId.trim();
    if (id.isEmpty) return;
    _stopped = false;
    _roomId = id;
    _accessToken = accessToken;
    _onConnected = onConnected;
    _onMessage = onMessage;
    _onPresence = onPresence;
    _onDjUpdate = onDjUpdate;
    _onSong = onSong;
    _onGift = onGift;
    _onRoomUpdate = onRoomUpdate;
    _onModeration = onModeration;
    _onAnnouncement = onAnnouncement;
    _onFortuneRequest = onFortuneRequest;
    _onTyping = onTyping;
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

    VoiceRoomDebugLog.sseConnect(roomId: id, url: streamUrlFor(id));

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
        onError: (_) => _scheduleReconnect(),
        onDone: () => _scheduleReconnect(),
        cancelOnError: false,
      );
    } catch (e) {
      if (kDebugMode) debugPrint('ChatRoomSseService: $e');
      _scheduleReconnect();
    }
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

    Map<String, dynamic> map;
    try {
      final decoded = jsonDecode(payload);
      if (decoded is! Map) return;
      map = Map<String, dynamic>.from(decoded);
    } catch (_) {
      map = {'content': payload};
    }

    final type = chatRoomSseEventTypeFrom(
      map['type']?.toString() ?? eventName,
    );
    final sseEvent = ChatRoomSseEvent(
      type: type,
      data: map,
      eventName: eventName,
    );
    if (!_events.isClosed) _events.add(sseEvent);
    _dispatch(type, map);
  }

  void _dispatch(ChatRoomSseEventType type, Map<String, dynamic> map) {
    switch (type) {
      case ChatRoomSseEventType.connected:
        _onConnected?.call();
        return;
      case ChatRoomSseEventType.heartbeat:
        return;
      case ChatRoomSseEventType.message:
        final msg = _parseMessage(map);
        if (msg != null) _onMessage?.call(msg);
        final batch = map['messages'];
        if (batch is List) {
          for (final raw in batch) {
            if (raw is! Map) continue;
            final m = ChatRoomMessage.fromJson(Map<String, dynamic>.from(raw));
            if (m.content.isNotEmpty) _onMessage?.call(m);
          }
        }
        return;
      case ChatRoomSseEventType.dj:
      case ChatRoomSseEventType.music:
        VoiceRoomDebugLog.djUpdate(
          roomId: _roomId ?? '',
          playing: map['playing'] == true,
          musicUrl: map['musicUrl']?.toString(),
          source: 'sse',
        );
        _onDjUpdate?.call(map);
        return;
      case ChatRoomSseEventType.song:
        _onSong?.call(map);
        _onDjUpdate?.call(map);
        return;
      case ChatRoomSseEventType.gift:
        _onGift?.call(map);
        return;
      case ChatRoomSseEventType.presence:
      case ChatRoomSseEventType.userJoin:
      case ChatRoomSseEventType.userLeave:
        final users = _parseUsers(map);
        if (users != null && users.isNotEmpty) _onPresence?.call(users);
        return;
      case ChatRoomSseEventType.roomUpdate:
        _onRoomUpdate?.call(map);
        return;
      case ChatRoomSseEventType.moderation:
        _onModeration?.call(map);
        return;
      case ChatRoomSseEventType.announcement:
        _onAnnouncement?.call(map);
        return;
      case ChatRoomSseEventType.fortuneRequest:
        _onFortuneRequest?.call(map);
        return;
      case ChatRoomSseEventType.unknown:
        if (map['typing'] is List) {
          final users = (map['typing'] as List)
              .map((e) => e.toString())
              .where((s) => s.isNotEmpty)
              .toList();
          if (users.isNotEmpty) _onTyping?.call(users);
        }
        if (map.containsKey('musicUrl') || map.containsKey('playing')) {
          _onDjUpdate?.call(map);
          return;
        }
        final users = _parseUsers(map);
        if (users != null && users.isNotEmpty) {
          _onPresence?.call(users);
          return;
        }
        final msg = _parseMessage(map);
        if (msg != null) _onMessage?.call(msg);
    }
  }

  List<ChatRoomPresence>? _parseUsers(Map<String, dynamic> map) {
    dynamic raw = map['users'] ?? map['presence'] ?? map['members'];
    if (raw == null && map['user'] is Map) raw = [map['user']];
    if (raw is! List) return null;
    return raw
        .whereType<Map>()
        .map((e) => ChatRoomPresence.fromJson(Map<String, dynamic>.from(e)))
        .where((u) => u.id.isNotEmpty)
        .toList();
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

  void _scheduleReconnect() {
    if (_stopped || _roomId == null) return;
    _reconnectTimer?.cancel();
    _reconnectAttempt++;
    final delay = Duration(seconds: (_reconnectAttempt.clamp(1, 6) * 2));
    VoiceRoomDebugLog.sseReconnect(
      roomId: _roomId ?? '',
      attempt: _reconnectAttempt,
      delaySec: delay.inSeconds,
    );
    _reconnectTimer = Timer(delay, () {
      if (!_stopped) unawaited(_openStream());
    });
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
    await _closeStreamOnly();
  }

  void dispose() {
    unawaited(disconnect());
    _events.close();
  }
}

/// Geriye dönük alias — mevcut provider adı korunur.
typedef VoiceRoomSseService = ChatRoomSseService;
