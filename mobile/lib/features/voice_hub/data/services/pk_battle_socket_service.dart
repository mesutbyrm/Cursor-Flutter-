import 'package:flutter/foundation.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;

import '../../../../core/config/env.dart';
import '../../domain/pk/pk_battle_remote_models.dart';
import 'voice_room_socket_helper.dart';

/// PK socket — pk:invite, pk:score-update, pk:end, …
class PkBattleSocketService {
  io.Socket? _socket;
  void Function(PkBattleRemote battle, String event)? _onUpdate;
  List<String> _roomKeys = const [];
  String? _streamId;
  String? _battleId;

  void connect({
    String? roomId,
    String? alternateRoomId,
    String? streamId,
    String? battleId,
    required void Function(PkBattleRemote battle, String event) onUpdate,
    Future<String?> Function()? accessToken,
  }) {
    _onUpdate = onUpdate;
    _streamId = streamId;
    _battleId = battleId;
    _roomKeys = roomId == null
        ? const []
        : VoiceRoomSocketHelper.joinKeys(
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

        void bind(String name) {
          _socket!.on(name, (data) => _handleEvent(name, data));
        }

        for (final ev in const [
          'pk:invite',
          'pk:accept',
          'pk:reject',
          'pk:start',
          'pk:score-update',
          'pk:gift',
          'pk:end',
          'pk:winner',
          'pkBattle',
          'pkBattleUpdated',
          'PK_UPDATED',
        ]) {
          bind(ev);
        }

        _socket!
          ..onConnect((_) => _joinChannels())
          ..onReconnect((_) => _joinChannels())
          ..connect();
      } catch (e) {
        debugPrint('PK socket: $e');
      }
    });
  }

  void _joinChannels() {
    VoiceRoomSocketHelper.emitJoinRooms(_socket, _roomKeys);
    final sid = _streamId?.trim();
    if (sid != null && sid.isNotEmpty) {
      _socket?.emit('joinStream', {'streamId': sid});
    }
    final bid = _battleId?.trim();
    if (bid != null && bid.isNotEmpty) {
      _socket?.emit('joinPk', {'battleId': bid});
    }
  }

  void _handleEvent(String eventName, dynamic data) {
    if (data is! Map) return;
    final map = Map<String, dynamic>.from(data);
    final raw = map['battle'] ?? map['pk'] ?? map;
    if (raw is! Map) return;
    final battle = PkBattleRemote.fromJson(Map<String, dynamic>.from(raw));
    if (battle.id.isEmpty) return;
    _battleId = battle.id;
    _onUpdate?.call(battle, map['event']?.toString() ?? eventName);
  }

  void disconnect() {
    for (final roomId in _roomKeys) {
      if (_socket?.connected == true) {
        _socket?.emit('leaveRoom', {'roomId': roomId});
      }
    }
    final sid = _streamId?.trim();
    if (sid != null && sid.isNotEmpty && _socket?.connected == true) {
      _socket?.emit('leaveStream', {'streamId': sid});
    }
    final bid = _battleId?.trim();
    if (bid != null && bid.isNotEmpty && _socket?.connected == true) {
      _socket?.emit('leavePk', {'battleId': bid});
    }
    _socket?.dispose();
    _socket = null;
    _onUpdate = null;
    _roomKeys = const [];
    _streamId = null;
    _battleId = null;
  }
}
