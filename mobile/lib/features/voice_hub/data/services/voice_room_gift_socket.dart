import 'package:flutter/foundation.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;

import '../../../../core/config/env.dart';
import '../../../live/data/datasources/live_gifts_remote_datasource.dart';
import '../../../live/domain/entities/live_gift_event.dart';

/// Sesli oda hediye socket — `joinRoom` + `gift` olayları.
class VoiceRoomGiftSocket {
  VoiceRoomGiftSocket(this._remote);

  final LiveGiftsRemoteDataSource _remote;
  io.Socket? _socket;
  void Function(LiveGiftEvent)? _onEvent;

  void connect({
    required String roomId,
    required void Function(LiveGiftEvent event) onEvent,
  }) {
    _onEvent = onEvent;
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
          ..on('gift', (data) => _emit(data, roomId))
          ..on('giftSent', (data) => _emit(data, roomId))
          ..connect();
      } catch (e) {
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

  void disconnect() {
    _socket?.dispose();
    _socket = null;
    _onEvent = null;
  }
}
