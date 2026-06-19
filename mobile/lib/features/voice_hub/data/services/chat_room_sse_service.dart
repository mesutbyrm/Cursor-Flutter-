import 'dart:async';

import '../../../../core/network/api_endpoints.dart';
import '../../../../core/network/sse/base_sse_service.dart';
import '../../domain/entities/chat_room_message.dart';
import '../../domain/entities/chat_room_presence.dart';
import '../../domain/entities/chat_room_sse_event.dart';
import 'voice_room_debug_log.dart';

/// Sohbet odası SSE — `GET /api/chat/rooms/{roomId}/stream`.
class ChatRoomSseService extends BaseSseService {
  ChatRoomSseService() : _events = StreamController<ChatRoomSseEvent>.broadcast();

  final StreamController<ChatRoomSseEvent> _events;
  Stream<ChatRoomSseEvent> get events => _events.stream;

  String? _roomId;

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

  static String streamUrlFor(String roomId) {
    final base = BaseSseService.createSseDio().options.baseUrl
        .replaceAll(RegExp(r'/$'), '');
    return '$base${ApiEndpoints.chatRoomStream(roomId.trim())}';
  }

  @override
  String streamPath() => ApiEndpoints.chatRoomStream(_roomId ?? '');

  @override
  bool get requiresAuth => false;

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
    _roomId = id;
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
    VoiceRoomDebugLog.sseConnect(roomId: id, url: streamUrlFor(id));
    await super.openConnection(accessToken: accessToken);
  }

  @override
  void onReconnecting(int attempt) {
    VoiceRoomDebugLog.sseReconnect(
      roomId: _roomId ?? '',
      attempt: attempt,
      delaySec: 0,
    );
  }

  @override
  void onSseBlock(String block) {
    final map = BaseSseService.parseSseJsonBlock(block);
    if (map == null) return;

    String? eventName;
    for (final line in block.split('\n')) {
      if (line.startsWith('event:')) {
        eventName = line.substring(6).trim();
      }
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

  @override
  Future<void> disconnect() async {
    _roomId = null;
    await super.disconnect();
  }

  @override
  void dispose() {
    unawaited(disconnect());
    _events.close();
    super.dispose();
  }
}

/// Geriye dönük alias — mevcut provider adı korunur.
typedef VoiceRoomSseService = ChatRoomSseService;
