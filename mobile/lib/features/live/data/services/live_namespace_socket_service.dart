import 'package:flutter/foundation.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;

import '../../../../core/config/env.dart';
import '../../../../core/network/live_debug_log.dart';
import '../../../voice_hub/data/services/voice_room_socket_helper.dart';

/// Socket.IO `/live` namespace — PK skor, misafir, yeniden bağlanma.
/// Backend: `canlifal.com/live` · auth: JWT `token`.
class LiveNamespaceSocketService {
  io.Socket? _socket;
  String? _streamId;
  List<String> _streamIds = const [];
  String? _battleId;

  bool get connected => _socket?.connected ?? false;

  void connect({
    required Future<String?> Function() accessToken,
    String? streamId,
    List<String>? streamIds,
    String? battleId,
    void Function(Map<String, dynamic> payload)? onPkScoreUpdate,
    void Function(Map<String, dynamic> payload)? onPkInvite,
    void Function(Map<String, dynamic> guest)? onGuestJoined,
    void Function(Map<String, dynamic> payload)? onGuestLeft,
    void Function()? onReconnect,
    void Function(bool connected)? onConnectionChanged,
  }) {
    _streamId = streamId;
    if (streamIds != null && streamIds.isNotEmpty) {
      _streamIds = streamIds
          .map((s) => s.trim())
          .where((s) => s.isNotEmpty)
          .toSet()
          .toList(growable: false);
    } else if (streamId != null && streamId.trim().isNotEmpty) {
      _streamIds = [streamId.trim()];
    } else {
      _streamIds = const [];
    }
    _battleId = battleId;

    Future.microtask(() async {
      try {
        final token = await accessToken();
        _socket?.dispose();

        final base = Env.apiBaseUrl.trim().replaceAll(RegExp(r'/+$'), '');
        _socket = io.io(
          '$base/live',
          VoiceRoomSocketHelper.baseOptions(bearerToken: token).build(),
        );

        _socket!
          ..onConnect((_) {
            LiveDebugLog.log('live.ns.connect', {
              'streamId': streamId,
              'battleId': battleId,
            });
            onConnectionChanged?.call(true);
            _emitJoins();
          })
          ..onDisconnect((_) {
            LiveDebugLog.log('live.ns.disconnect', {});
            onConnectionChanged?.call(false);
          })
          ..onReconnect((_) {
            LiveDebugLog.log('live.ns.reconnect', {});
            onConnectionChanged?.call(true);
            onReconnect?.call();
            _emitJoins();
          })
          ..on('pk_score_update', (data) => _emitMap(data, onPkScoreUpdate))
          ..on('pk:score-update', (data) => _emitMap(data, onPkScoreUpdate))
          ..on('PK_SCORE_UPDATE', (data) => _emitMap(data, onPkScoreUpdate))
          ..on('pk_invite', (data) => _emitMap(data, onPkInvite))
          ..on('pkInvite', (data) => _emitMap(data, onPkInvite))
          ..on('PK_INVITE', (data) => _emitMap(data, onPkInvite))
          ..on('guest_joined', (data) => _emitMap(data, onGuestJoined))
          ..on('guestJoined', (data) => _emitMap(data, onGuestJoined))
          ..on('GUEST_JOINED', (data) => _emitMap(data, onGuestJoined))
          ..on('guest_left', (data) => _emitMap(data, onGuestLeft))
          ..on('guestLeft', (data) => _emitMap(data, onGuestLeft))
          ..connect();
      } catch (e) {
        debugPrint('LiveNamespaceSocket: $e');
      }
    });
  }

  void _emitJoins() {
    final joined = <String>{};
    for (final sid in _streamIds) {
      if (sid.isEmpty || !joined.add(sid)) continue;
      _socket?.emit('joinStream', {'streamId': sid});
    }
    final streamId = _streamId?.trim();
    if (streamId != null && streamId.isNotEmpty && joined.add(streamId)) {
      _socket?.emit('joinStream', {'streamId': streamId});
    }
    final battleId = _battleId?.trim();
    if (battleId != null && battleId.isNotEmpty) {
      _socket?.emit('joinBattle', {'battleId': battleId, 'matchId': battleId});
    }
  }

  void updateRooms({
    String? streamId,
    List<String>? streamIds,
    String? battleId,
  }) {
    if (streamIds != null) {
      _streamIds = streamIds
          .map((s) => s.trim())
          .where((s) => s.isNotEmpty)
          .toSet()
          .toList(growable: false);
    }
    _streamId = streamId ?? _streamId;
    _battleId = battleId ?? _battleId;
    if (_socket?.connected == true) _emitJoins();
  }

  void _emitMap(
    dynamic data,
    void Function(Map<String, dynamic> payload)? handler,
  ) {
    if (handler == null) return;
    if (data is Map) {
      handler(Map<String, dynamic>.from(data));
    }
  }

  void disconnect() {
    final battleId = _battleId;
    if (_socket?.connected == true) {
      final left = <String>{};
      for (final sid in _streamIds) {
        if (sid.isEmpty || !left.add(sid)) continue;
        _socket?.emit('leaveStream', {'streamId': sid});
      }
      final streamId = _streamId?.trim();
      if (streamId != null && streamId.isNotEmpty && left.add(streamId)) {
        _socket?.emit('leaveStream', {'streamId': streamId});
      }
      if (battleId != null && battleId.isNotEmpty) {
        _socket?.emit('leaveBattle', {'battleId': battleId});
      }
    }
    _socket?.dispose();
    _socket = null;
    _streamId = null;
    _streamIds = const [];
    _battleId = null;
  }
}
