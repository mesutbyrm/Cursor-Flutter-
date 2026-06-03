import 'package:flutter/foundation.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;

import '../../../../core/config/env.dart';
import '../../domain/entities/chat_room_message.dart';
import 'voice_room_socket_helper.dart';

/// Sesli oda sohbet — anlık mesaj olayları (web ile aynı Socket.IO odaları).
class VoiceRoomChatSocket {
  io.Socket? _socket;
  void Function(ChatRoomMessage message)? _onMessage;
  List<String> _joinKeys = const [];

  void connect({
    required String roomId,
    String? alternateRoomId,
    required void Function(ChatRoomMessage message) onMessage,
    Future<String?> Function()? accessToken,
  }) {
    _onMessage = onMessage;
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
          ..onConnect((_) => VoiceRoomSocketHelper.emitJoinRooms(_socket, _joinKeys))
          ..onReconnect((_) =>
              VoiceRoomSocketHelper.emitJoinRooms(_socket, _joinKeys))
          ..on('chatMessage', (data) => _handle(data))
          ..on('message', (data) => _handle(data))
          ..on('roomMessage', (data) => _handle(data))
          ..connect();
      } catch (e) {
        debugPrint('Voice chat socket: $e');
      }
    });
  }

  void _handle(dynamic data) {
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
      if (msg.content.isNotEmpty) _onMessage?.call(msg);
    } catch (e) {
      debugPrint('Voice chat parse: $e');
    }
  }

  void disconnect() {
    _socket?.dispose();
    _socket = null;
    _onMessage = null;
    _joinKeys = const [];
  }
}
