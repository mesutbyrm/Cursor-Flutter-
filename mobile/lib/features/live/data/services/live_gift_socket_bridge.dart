import 'package:flutter/foundation.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;

import '../../../../core/config/env.dart';
import '../../../../core/network/live_debug_log.dart';
import '../../domain/entities/live_gift_event.dart';
import '../../domain/entities/live_stream_chat_message.dart';
import '../datasources/live_gifts_remote_datasource.dart';

/// Socket.IO — canlı yayın: hediye, sohbet, izleyici, yayın sonu.
class LiveGiftSocketBridge {
  LiveGiftSocketBridge(this._remote);

  final LiveGiftsRemoteDataSource _remote;
  io.Socket? _socket;
  String? _streamId;

  bool get connected => _socket?.connected ?? false;

  void connect({
    required String streamId,
    void Function(LiveGiftEvent event)? onEvent,
    void Function(LiveStreamChatMessage message)? onChat,
    void Function(int viewerCount)? onViewerCount,
    VoidCallback? onStreamEnded,
    void Function(Map<String, dynamic> battle)? onPkBattle,
  }) {
    _streamId = streamId;
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
          ..onConnect((_) {
            LiveDebugLog.log('socket.stream.join', {'streamId': streamId});
            _socket?.emit('joinStream', {'streamId': streamId});
          })
          ..on('gift', (data) => _emitGift(data, streamId, onEvent))
          ..on('giftSent', (data) => _emitGift(data, streamId, onEvent))
          ..on('streamMessage', (data) => _emitChat(data, onChat))
          ..on('chatMessage', (data) => _emitChat(data, onChat))
          ..on('message', (data) => _emitChat(data, onChat))
          ..on('viewerCount', (data) => _emitViewers(data, onViewerCount))
          ..on('viewerCountUpdated', (data) => _emitViewers(data, onViewerCount))
          ..on('streamEnded', (_) {
            LiveDebugLog.log('socket.stream.ended', {'streamId': streamId});
            onStreamEnded?.call();
          })
          ..on('STREAM_ENDED', (_) => onStreamEnded?.call())
          ..on('pkBattle', (data) => _emitPk(data, onPkBattle))
          ..on('pkBattleUpdated', (data) => _emitPk(data, onPkBattle))
          ..on('PK_UPDATED', (data) => _emitPk(data, onPkBattle))
          ..on('pk:score-update', (data) => _emitPk(data, onPkBattle))
          ..on('pk:end', (data) => _emitPk(data, onPkBattle))
          ..on('pk:winner', (data) => _emitPk(data, onPkBattle))
          ..connect();
      } catch (e) {
        debugPrint('Gift socket: $e');
      }
    });
  }

  void _emitGift(
    dynamic data,
    String streamId,
    void Function(LiveGiftEvent event)? onEvent,
  ) {
    if (onEvent == null || data is! Map) return;
    final ev = _remote.parseGiftEvent(
      Map<String, dynamic>.from(data),
      streamId: streamId,
    );
    if (ev != null) onEvent(ev);
  }

  void _emitChat(
    dynamic data,
    void Function(LiveStreamChatMessage message)? onChat,
  ) {
    if (onChat == null || data is! Map) return;
    final map = Map<String, dynamic>.from(data);
    final raw = map['message'] is Map ? map['message'] : map;
    if (raw is! Map) return;
    final msg = LiveStreamChatMessage.fromJson(
      Map<String, dynamic>.from(raw),
    );
    if (msg.content.isNotEmpty) onChat(msg);
  }

  void _emitPk(
    dynamic data,
    void Function(Map<String, dynamic> battle)? onPkBattle,
  ) {
    if (onPkBattle == null || data is! Map) return;
    final map = Map<String, dynamic>.from(data);
    final raw = map['battle'] ?? map['pk'] ?? map;
    if (raw is Map) {
      onPkBattle(Map<String, dynamic>.from(raw));
    }
  }

  void _emitViewers(
    dynamic data,
    void Function(int viewerCount)? onViewerCount,
  ) {
    if (onViewerCount == null || data is! Map) return;
    final map = Map<String, dynamic>.from(data);
    final count = map['viewerCount'] ?? map['viewers'] ?? map['watching'];
    if (count is num) onViewerCount(count.round());
  }

  void disconnect() {
    final id = _streamId;
    if (id != null && _socket?.connected == true) {
      _socket?.emit('leaveStream', {'streamId': id});
    }
    _socket?.dispose();
    _socket = null;
    _streamId = null;
  }
}
