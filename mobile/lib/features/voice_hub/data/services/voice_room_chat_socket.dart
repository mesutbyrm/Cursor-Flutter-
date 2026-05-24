import 'package:flutter/foundation.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;

import '../../../../core/config/env.dart';
import '../../domain/entities/chat_room_message.dart';

/// Sesli oda sohbet — anlık mesaj olayları.
class VoiceRoomChatSocket {
  io.Socket? _socket;
  void Function(ChatRoomMessage message)? _onMessage;

  void connect({
    required String roomId,
    required void Function(ChatRoomMessage message) onMessage,
  }) {
    _onMessage = onMessage;
    Future.microtask(() {
      try {
        _socket?.dispose();
        _socket = io.io(
          Env.siteOrigin,
          io.OptionBuilder()
              .setTransports(['websocket', 'polling'])
              .disableAutoConnect()
              .setTimeout(5000)
              .build(),
        );
        _socket!
          ..onConnect((_) => _socket?.emit('joinRoom', {'roomId': roomId}))
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
  }
}
