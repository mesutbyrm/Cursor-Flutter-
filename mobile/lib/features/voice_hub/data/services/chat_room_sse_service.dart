import 'dart:async';

import '../../../../core/network/api_endpoints.dart';
import '../../../../core/network/sse/base_sse_service.dart';
import '../../domain/entities/chat_room_message.dart';
import '../../domain/entities/chat_room_presence.dart';
import '../../domain/entities/chat_room_sse_event.dart';
import '../../domain/pk/pk_battle_remote_models.dart';
import '../../presentation/utils/voice_sse_dj_payload.dart';
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
  void Function(Map<String, dynamic> payload)? _onUserJoin;
  void Function(Map<String, dynamic> payload)? _onUserLeave;
  void Function(Map<String, dynamic> payload)? _onDjUpdate;
  void Function(Map<String, dynamic> payload)? _onSong;
  void Function(Map<String, dynamic> payload)? _onGift;
  void Function(Map<String, dynamic> payload)? _onRoomUpdate;
  void Function(Map<String, dynamic> payload)? _onModeration;
  void Function(Map<String, dynamic> payload)? _onAnnouncement;
  void Function(Map<String, dynamic> payload)? _onSystem;
  void Function(Map<String, dynamic> payload)? _onFortuneRequest;
  void Function(PkBattleRemote battle, String event)? _onPk;
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
    void Function(Map<String, dynamic> payload)? onUserJoin,
    void Function(Map<String, dynamic> payload)? onUserLeave,
    void Function(Map<String, dynamic> payload)? onDjUpdate,
    void Function(Map<String, dynamic> payload)? onSong,
    void Function(Map<String, dynamic> payload)? onGift,
    void Function(Map<String, dynamic> payload)? onRoomUpdate,
    void Function(Map<String, dynamic> payload)? onModeration,
    void Function(Map<String, dynamic> payload)? onAnnouncement,
    void Function(Map<String, dynamic> payload)? onSystem,
    void Function(Map<String, dynamic> payload)? onFortuneRequest,
    void Function(PkBattleRemote battle, String event)? onPk,
    void Function(List<String> users)? onTyping,
  }) async {
    final id = roomId.trim();
    if (id.isEmpty) return;
    _roomId = id;
    _onConnected = onConnected;
    _onMessage = onMessage;
    _onPresence = onPresence;
    _onUserJoin = onUserJoin;
    _onUserLeave = onUserLeave;
    _onDjUpdate = onDjUpdate;
    _onSong = onSong;
    _onGift = onGift;
    _onRoomUpdate = onRoomUpdate;
    _onModeration = onModeration;
    _onAnnouncement = onAnnouncement;
    _onSystem = onSystem;
    _onFortuneRequest = onFortuneRequest;
    _onPk = onPk;
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
      case ChatRoomSseEventType.music: {
        final djMap = unwrapVoiceSseDjPayload(map);
        VoiceRoomDebugLog.djUpdate(
          roomId: _roomId ?? '',
          playing: voiceSseDjIsPlaying(djMap),
          musicUrl: djMap['musicUrl']?.toString(),
          source: 'sse',
        );
        _onDjUpdate?.call(djMap);
        return;
      }
      case ChatRoomSseEventType.song: {
        final djMap = unwrapVoiceSseDjPayload(map);
        _onSong?.call(djMap);
        _onDjUpdate?.call(djMap);
        return;
      }
      case ChatRoomSseEventType.gift:
        _onGift?.call(map);
        return;
      case ChatRoomSseEventType.presence:
        final users = _parseUsers(map);
        if (users != null && users.isNotEmpty) _onPresence?.call(users);
        return;
      case ChatRoomSseEventType.userJoin:
        _onUserJoin?.call(map);
        final joined = _parseUsers(map);
        if (joined != null && joined.isNotEmpty) _onPresence?.call(joined);
        return;
      case ChatRoomSseEventType.userLeave:
        _onUserLeave?.call(map);
        final remaining = _parseUsers(map);
        if (remaining != null && remaining.isNotEmpty) {
          _onPresence?.call(remaining);
        }
        return;
      case ChatRoomSseEventType.roomUpdate:
        _onRoomUpdate?.call(map);
        return;
      case ChatRoomSseEventType.moderation:
        _onModeration?.call(map);
        return;
      case ChatRoomSseEventType.system:
        _dispatchSystemEvent(map);
        return;
      case ChatRoomSseEventType.announcement:
        _onAnnouncement?.call(map);
        return;
      case ChatRoomSseEventType.fortuneRequest:
        _onFortuneRequest?.call(map);
        return;
      case ChatRoomSseEventType.pk:
        _emitPk(map);
        return;
      case ChatRoomSseEventType.typing:
        final users = (map['users'] is List
                ? map['users'] as List
                : map['typing'] is List
                    ? map['typing'] as List
                    : const [])
            .map((e) => e.toString())
            .where((s) => s.isNotEmpty)
            .toList();
        if (users.isNotEmpty) _onTyping?.call(users);
        return;
      case ChatRoomSseEventType.unknown:
        if (map['typing'] is List) {
          final users = (map['typing'] as List)
              .map((e) => e.toString())
              .where((s) => s.isNotEmpty)
              .toList();
          if (users.isNotEmpty) _onTyping?.call(users);
        }
        if (map.containsKey('musicUrl') ||
            map.containsKey('playing') ||
            map.containsKey('isPlaying') ||
            map['data'] is Map) {
          _onDjUpdate?.call(unwrapVoiceSseDjPayload(map));
          return;
        }
        if (_tryEmitPk(map)) return;
        final users = _parseUsers(map);
        if (users != null && users.isNotEmpty) {
          _onPresence?.call(users);
          return;
        }
        final msg = _parseMessage(map);
        if (msg != null) _onMessage?.call(msg);
    }
  }

  void _dispatchSystemEvent(Map<String, dynamic> map) {
    _onSystem?.call(map);
    final event = map['event']?.toString().toUpperCase().trim() ?? '';
    switch (event) {
      case 'ANNOUNCEMENT':
        _onAnnouncement?.call(map);
        return;
      case 'USER_KICKED':
      case 'USER_BANNED':
      case 'USER_MUTED':
      case 'USER_UNMUTED':
      case 'CHAT_CLEARED':
      case 'MESSAGES_CLEARED':
      case 'ROOM_MUTED':
      case 'ROOM_UNMUTED':
        _onModeration?.call(map);
        return;
      case 'ROLE_CHANGED':
      case 'ROLE_REMOVED':
      case 'ENTRY_ANNOUNCEMENT':
        return;
      default:
        if (map['message'] != null) {
          _onAnnouncement?.call(map);
        }
    }
  }

  List<ChatRoomPresence>? _parseUsers(Map<String, dynamic> map) {
    dynamic raw = map['users'] ?? map['presence'] ?? map['members'];
    if (raw == null && map['user'] is Map) raw = [map['user']];
    if (raw == null) {
      final userId = map['userId']?.toString() ?? map['id']?.toString();
      if (userId != null && userId.isNotEmpty) {
        raw = [map];
      }
    }
    if (raw is! List) return null;
    return raw
        .whereType<Map>()
        .map((e) => ChatRoomPresence.fromJson(Map<String, dynamic>.from(e)))
        .where((u) => u.id.isNotEmpty)
        .toList();
  }

  bool _tryEmitPk(Map<String, dynamic> map) {
    if (!map.containsKey('battle') && !map.containsKey('pk')) return false;
    _emitPk(map);
    return true;
  }

  void _emitPk(Map<String, dynamic> map) {
    final raw = map['battle'] ?? map['pk'] ?? map['data'];
    if (raw is! Map) return;
    final battle = PkBattleRemote.fromJson(Map<String, dynamic>.from(raw));
    if (battle.id.isEmpty) return;
    final event = map['event']?.toString() ??
        map['type']?.toString() ??
        'pk';
    _onPk?.call(battle, event);
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
