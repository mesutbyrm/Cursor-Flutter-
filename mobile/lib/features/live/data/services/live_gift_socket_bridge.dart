import 'package:flutter/foundation.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;

import '../../../../core/config/env.dart';
import '../../../voice_hub/domain/pk/pk_battle_remote_models.dart';
import '../../domain/entities/live_gift_event.dart';
import '../datasources/live_gifts_remote_datasource.dart';

/// Socket.IO varsa poll yerine anlık hediye olayları (sunucu destekliyorsa).
class LiveGiftSocketBridge {
  LiveGiftSocketBridge(this._remote);

  final LiveGiftsRemoteDataSource _remote;
  io.Socket? _socket;
  void Function(LiveGiftEvent)? _onEvent;
  void Function(PkBattleRemote battle, String event)? _onPk;

  bool get connected => _socket?.connected ?? false;

  void connect({
    required String streamId,
    required void Function(LiveGiftEvent event) onEvent,
    void Function(PkBattleRemote battle, String event)? onPkBattle,
  }) {
    _onEvent = onEvent;
    _onPk = onPkBattle;
    // Socket yalnızca canlı oda açıldığında; hata uygulamayı düşürmez.
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
          ..on('pkBattle', (data) => _emitPk(data))
          ..on('pkBattleUpdated', (data) => _emitPk(data))
          ..on('pk:score-update', (data) => _emitPk(data))
          ..on('pk:end', (data) => _emitPk(data))
          ..on('pk:winner', (data) => _emitPk(data))
          ..connect();
      } catch (e) {
        debugPrint('Gift socket: $e');
      }
    });
  }

  void _emitPk(dynamic data) {
    if (data is! Map) return;
    final map = Map<String, dynamic>.from(data);
    final raw = map['battle'] ?? map['pk'] ?? map;
    if (raw is! Map) return;
    final battle = PkBattleRemote.fromJson(Map<String, dynamic>.from(raw));
    if (battle.id.isEmpty) return;
    _onPk?.call(battle, map['event']?.toString() ?? 'pkBattle');
  }

  void disconnect() {
    _socket?.dispose();
    _socket = null;
    _onEvent = null;
    _onPk = null;
  }
}
