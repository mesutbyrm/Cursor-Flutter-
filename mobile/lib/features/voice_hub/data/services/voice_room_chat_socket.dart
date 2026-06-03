import 'package:flutter/foundation.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;

import '../../../../core/config/env.dart';
import '../../domain/entities/chat_room_message.dart';
import '../../domain/entities/chat_room_presence.dart';
import 'voice_room_debug_log.dart';
import 'voice_room_socket_helper.dart';

/// @deprecated Üretim SSE kullanır — [VoiceRoomSseService]. Socket.IO bağlanmaz.
/// Sesli oda sohbet — eski Socket.IO istemcisi (yerel API aynası için).
class VoiceRoomChatSocket {
  io.Socket? _socket;
  void Function(ChatRoomMessage message)? _onMessage;
  void Function(List<ChatRoomPresence> users)? _onPresence;
  List<String> _joinKeys = const [];

  void connect({
    required String roomId,
    String? alternateRoomId,
    required void Function(ChatRoomMessage message) onMessage,
    void Function(List<ChatRoomPresence> users)? onPresence,
    Future<String?> Function()? accessToken,
  }) {
    _onMessage = onMessage;
    _onPresence = onPresence;
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
            VoiceRoomDebugLog.log('socket.connect', {'rooms': _joinKeys.join(',')});
            VoiceRoomSocketHelper.emitJoinRooms(_socket, _joinKeys);
          })
          ..onDisconnect((_) => VoiceRoomDebugLog.log('socket.disconnect'))
          ..onReconnect((_) {
            VoiceRoomDebugLog.log('socket.reconnect');
            VoiceRoomSocketHelper.emitJoinRooms(_socket, _joinKeys);
          })
          ..on('chatMessage', (data) => _handleMessage(data, 'chatMessage'))
          ..on('message', (data) => _handleMessage(data, 'message'))
          ..on('roomMessage', (data) => _handleMessage(data, 'roomMessage'))
          ..on('roomUsers', (data) => _handlePresence(data, 'roomUsers'))
          ..on('presenceUpdated', (data) => _handlePresence(data, 'presenceUpdated'))
          ..on('userJoined', (data) => _handlePresence(data, 'userJoined'))
          ..on('userLeft', (data) => _handlePresence(data, 'userLeft'))
          ..connect();
        VoiceRoomDebugLog.log('socket.connecting', {'origin': Env.siteOrigin});
      } catch (e) {
        VoiceRoomDebugLog.log('socket.error', {'error': e.toString()});
        debugPrint('Voice chat socket: $e');
      }
    });
  }

  void _handleMessage(dynamic data, String event) {
    Map<String, dynamic>? map;
    if (data is Map) {
      map = Map<String, dynamic>.from(data);
      if (map['message'] is Map) {
        map = Map<String, dynamic>.from(map['message'] as Map);
      } else if (map['data'] is Map) {
        final inner = map['data'] as Map;
        if (inner['message'] is Map) {
          map = Map<String, dynamic>.from(inner['message'] as Map);
        } else {
          map = Map<String, dynamic>.from(inner);
        }
      }
    }
    if (map == null) return;
    try {
      final msg = ChatRoomMessage.fromJson(map);
      if (msg.content.isNotEmpty) {
        VoiceRoomDebugLog.log('socket.$event', {'id': msg.id});
        _onMessage?.call(msg);
      }
    } catch (e) {
      debugPrint('Voice chat parse: $e');
    }
  }

  void _handlePresence(dynamic data, String event) {
    final users = _parsePresenceList(data);
    if (users == null || users.isEmpty) return;
    VoiceRoomDebugLog.log('socket.$event', {'count': users.length});
    _onPresence?.call(users);
  }

  List<ChatRoomPresence>? _parsePresenceList(dynamic data) {
    if (data is! Map) return null;
    final map = Map<String, dynamic>.from(data);
    dynamic raw = map['users'] ?? map['presence'] ?? map['members'];
    if (raw == null && map['user'] is Map) {
      raw = [map['user']];
    }
    if (raw is! List) return null;
    return raw
        .map((e) => ChatRoomPresence.fromJson(Map<String, dynamic>.from(e as Map)))
        .where((u) => u.id.isNotEmpty)
        .toList();
  }

  void disconnect() {
    VoiceRoomDebugLog.log('socket.disconnect.manual');
    _socket?.dispose();
    _socket = null;
    _onMessage = null;
    _onPresence = null;
    _joinKeys = const [];
  }
}
