import 'package:flutter/foundation.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;

import '../../../../core/config/env.dart';
import '../../domain/entities/chat_room_message.dart';
import '../../domain/entities/chat_room_presence.dart';
import '../../../live/data/datasources/live_gifts_remote_datasource.dart';
import '../../../live/domain/entities/live_gift_event.dart';
import 'voice_room_debug_log.dart';
import 'voice_room_socket_helper.dart';

/// Üretim `ChatPresenceRow` — Flutter domain karşılığı.
typedef ChatPresenceRow = ChatRoomPresence;

/// Sesli oda hediye + presence socket — `joinRoom` + olay dinleyicileri.
class VoiceRoomGiftSocket {
  VoiceRoomGiftSocket(this._remote);

  final LiveGiftsRemoteDataSource _remote;
  io.Socket? _socket;
  void Function(LiveGiftEvent)? _onEvent;
  void Function(Map<String, dynamic> payload)? _onDjUpdate;
  void Function(ChatRoomMessage message)? _onMessage;
  void Function(List<ChatRoomPresence> users)? _onPresence;
  void Function(List<ChatPresenceRow> previous, List<ChatPresenceRow> current)?
      _onPresenceSnapshot;
  void Function(bool connected)? _onConnectionChanged;
  List<String> _joinKeys = const [];
  List<ChatPresenceRow> _lastPresence = const [];
  var _loggedPresencePayloadShape = false;

  void connect({
    required String roomId,
    String? alternateRoomId,
    required void Function(LiveGiftEvent event) onEvent,
    void Function(Map<String, dynamic> payload)? onDjUpdate,
    void Function(ChatRoomMessage message)? onMessage,
    void Function(List<ChatRoomPresence> users)? onPresence,
    void Function(List<ChatPresenceRow> previous, List<ChatPresenceRow> current)?
        onPresenceSnapshot,
    void Function(bool connected)? onConnectionChanged,
    Future<String?> Function()? accessToken,
  }) {
    _onEvent = onEvent;
    _onDjUpdate = onDjUpdate;
    _onMessage = onMessage;
    _onPresence = onPresence;
    _onPresenceSnapshot = onPresenceSnapshot;
    _onConnectionChanged = onConnectionChanged;
    _lastPresence = const [];
    _loggedPresencePayloadShape = false;
    _joinKeys = VoiceRoomSocketHelper.joinKeys(
      primary: roomId,
      alternate: alternateRoomId,
    );
    Future.microtask(() async {
      try {
        final token = accessToken != null ? await accessToken() : null;
        _socket?.dispose();
        _socket = io.io(
          Env.siteOrigin,
          VoiceRoomSocketHelper.baseOptions(bearerToken: token).build(),
        );
        _socket!
          ..onConnect((_) {
            VoiceRoomDebugLog.log('socket.connect', {
              'rooms': _joinKeys.join(','),
              'kind': 'gift',
            });
            _onConnectionChanged?.call(true);
            VoiceRoomSocketHelper.emitJoinRooms(_socket, _joinKeys);
          })
          ..onDisconnect((_) {
            VoiceRoomDebugLog.log('socket.disconnect', {'kind': 'gift'});
            _onConnectionChanged?.call(false);
          })
          ..onReconnect((_) {
            VoiceRoomDebugLog.log('socket.reconnect', {'kind': 'gift'});
            _onConnectionChanged?.call(true);
            VoiceRoomSocketHelper.emitJoinRooms(_socket, _joinKeys);
          })
          ..on('gift', (data) => _emit(data, roomId))
          ..on('giftSent', (data) => _emit(data, roomId))
          ..on('chatMessage', (data) => _emitMessage(data))
          ..on('message', (data) => _emitMessage(data))
          ..on('roomMessage', (data) => _emitMessage(data))
          ..on('roomUsers', (data) => _emitPresenceSnapshot(data, 'roomUsers'))
          ..on(
            'presenceUpdated',
            (data) => _emitPresenceSnapshot(data, 'presenceUpdated'),
          )
          ..on('userJoined', (data) => _emitPresenceSnapshot(data, 'userJoined'))
          ..on('userLeft', (data) => _emitPresenceSnapshot(data, 'userLeft'))
          ..on('dj', (data) => _emitDj(data))
          ..on('music', (data) => _emitDj(data))
          ..on('roomVideo', (data) => _emitDj(data))
          ..on('QUEUE_UPDATED', (data) => _emitDj(data))
          ..on('CURRENT_SONG_CHANGED', (data) => _emitDj(data))
          ..connect();
        VoiceRoomDebugLog.log('socket.connecting', {
          'origin': Env.siteOrigin,
          'kind': 'gift',
        });
      } catch (e) {
        VoiceRoomDebugLog.log('socket.error', {
          'error': e.toString(),
          'kind': 'gift',
        });
        debugPrint('Voice gift socket: $e');
      }
    });
  }

  void _emit(dynamic data, String roomId) {
    if (data is! Map) return;
    final ev = _remote.parseGiftEvent(
      Map<String, dynamic>.from(data),
      streamId: roomId,
    );
    if (ev != null) _onEvent?.call(ev);
  }

  void _emitMessage(dynamic data) {
    if (data is! Map) return;
    final map = Map<String, dynamic>.from(data);
    final raw = map['message'] is Map ? map['message'] : map;
    if (raw is! Map) return;
    final msg = ChatRoomMessage.fromJson(Map<String, dynamic>.from(raw));
    if (msg.content.isEmpty) return;
    VoiceRoomDebugLog.log('socket.message.recv', {'id': msg.id});
    _onMessage?.call(msg);
  }

  void _emitPresenceSnapshot(dynamic data, String eventName) {
    if (data is! Map) return;
    final map = Map<String, dynamic>.from(data);
    if (!_loggedPresencePayloadShape) {
      _loggedPresencePayloadShape = true;
      debugPrint(
        '[VoiceRoom] presence snapshot payload ($eventName): keys=${map.keys.toList()}',
      );
    }
    final next = _parsePresenceList(map, eventName: eventName);
    if (next == null) return;
    final previous = List<ChatPresenceRow>.from(_lastPresence);
    VoiceRoomDebugLog.log('socket.presence.snapshot', {
      'event': eventName,
      'prev': previous.length,
      'next': next.length,
    });
    _onPresenceSnapshot?.call(previous, next);
    _onPresence?.call(next);
    _lastPresence = next;
  }

  /// `giftHub.ts` emit şekilleri: tam liste veya delta + users.
  List<ChatPresenceRow>? _parsePresenceList(
    Map<String, dynamic> map, {
    required String eventName,
  }) {
    final fromUsers = _rowsFromRawList(map['users'] ?? map['presence'] ?? map['members']);
    if (fromUsers != null && fromUsers.isNotEmpty) {
      return fromUsers;
    }

    if (eventName == 'userJoined') {
      final joined = map['user'];
      if (joined is Map) {
        final row = ChatPresenceRow.fromJson(Map<String, dynamic>.from(joined));
        if (row.id.isEmpty) return null;
        final list = List<ChatPresenceRow>.from(_lastPresence);
        final idx = list.indexWhere((p) => p.id == row.id);
        if (idx >= 0) {
          list[idx] = row;
        } else {
          list.add(row);
        }
        return list;
      }
    }

    if (eventName == 'userLeft') {
      final leftId = map['userId']?.toString();
      if (leftId != null && leftId.isNotEmpty) {
        return _lastPresence.where((p) => p.id != leftId).toList();
      }
    }

    return fromUsers;
  }

  List<ChatPresenceRow>? _rowsFromRawList(dynamic raw) {
    if (raw is! List) return null;
    final users = raw
        .whereType<Map>()
        .map((e) => ChatPresenceRow.fromJson(Map<String, dynamic>.from(e)))
        .where((u) => u.id.isNotEmpty)
        .toList();
    return users.isEmpty ? null : users;
  }

  void _emitDj(dynamic data) {
    if (data is! Map) return;
    final map = Map<String, dynamic>.from(data);
    VoiceRoomDebugLog.log('socket.dj.recv', {
      'playing': map['playing'],
      'hasUrl': map['musicUrl'] != null,
      'type': map['type'],
    });
    _onDjUpdate?.call(map);
  }

  void disconnect() {
    for (final roomId in _joinKeys) {
      if (_socket?.connected == true) {
        _socket?.emit('leaveRoom', {'roomId': roomId});
      }
    }
    _socket?.dispose();
    _socket = null;
    _onEvent = null;
    _onDjUpdate = null;
    _onMessage = null;
    _onPresence = null;
    _onPresenceSnapshot = null;
    _onConnectionChanged = null;
    _joinKeys = const [];
    _lastPresence = const [];
    _loggedPresencePayloadShape = false;
  }
}
