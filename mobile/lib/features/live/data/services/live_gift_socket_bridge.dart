import 'package:flutter/foundation.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;

import '../../../../core/config/env.dart';
import '../../domain/entities/live_gift_event.dart';
import '../datasources/live_gifts_remote_datasource.dart';

/// Socket.IO varsa poll yerine anlık hediye olayları (sunucu destekliyorsa).
class LiveGiftSocketBridge {
  LiveGiftSocketBridge(this._remote);

  final LiveGiftsRemoteDataSource _remote;
  io.Socket? _socket;
  void Function(LiveGiftEvent)? _onEvent;

  bool get connected => _socket?.connected ?? false;

  void connect({
    required String streamId,
    required void Function(LiveGiftEvent event) onEvent,
  }) {
    _onEvent = onEvent;
    try {
      _socket?.dispose();
      _socket = io.io(
        Env.siteOrigin,
        io.OptionBuilder()
            .setTransports(['websocket', 'polling'])
            .disableAutoConnect()
            .build(),
      );
      _socket!
        ..onConnect((_) => _socket?.emit('joinStream', {'streamId': streamId}))
        ..on('gift', (data) {
          if (data is! Map) return;
          final map = Map<String, dynamic>.from(data);
          final ev = _remote.parseGiftEvent(map, streamId: streamId);
          if (ev != null) _onEvent?.call(ev);
        })
        ..on('giftSent', (data) {
          if (data is! Map) return;
          final map = Map<String, dynamic>.from(data);
          final ev = _remote.parseGiftEvent(map, streamId: streamId);
          if (ev != null) _onEvent?.call(ev);
        })
        ..connect();
    } catch (e) {
      debugPrint('Gift socket: $e');
    }
  }

  void disconnect() {
    _socket?.dispose();
    _socket = null;
    _onEvent = null;
  }
}
