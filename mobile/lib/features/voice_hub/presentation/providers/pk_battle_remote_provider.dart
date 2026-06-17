import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/dio_provider.dart';
import '../../../../core/network/token_storage.dart';
import '../../data/datasources/pk_battle_remote_datasource.dart';
import '../../data/services/pk_battle_socket_service.dart';
import '../../domain/pk/pk_battle_remote_models.dart';
import 'pk_battle_provider.dart';

final pkBattleRemoteDataSourceProvider = Provider<PkBattleRemoteDataSource>((ref) {
  return PkBattleRemoteDataSource(ref.watch(dioProvider));
});

final pkBattleSocketServiceProvider = Provider<PkBattleSocketService>((ref) {
  final s = PkBattleSocketService();
  ref.onDispose(s.disconnect);
  return s;
});

/// Sunucu PK senkronu — REST + Socket.IO.
class PkBattleRemoteController extends Notifier<PkBattleRemote?> {
  PkBattleSocketService get _socket => ref.read(pkBattleSocketServiceProvider);
  PkBattleRemoteDataSource get _api => ref.read(pkBattleRemoteDataSourceProvider);
  TokenStorage get _tokens => ref.read(tokenStorageProvider);

  @override
  PkBattleRemote? build() => null;

  Future<PkBattleRemote?> loadRoomBattle(String roomId, {String? alternateRoomId}) async {
    final battle = await _api.fetchRoomBattle(
      roomId,
      alternateRoomId: alternateRoomId,
    );
    if (battle != null) _apply(battle, 'load');
    return battle;
  }

  Future<PkBattleRemote?> loadStreamBattle(String streamId) async {
    final battle = await _api.fetchStreamBattle(streamId);
    if (battle != null) _apply(battle, 'load');
    return battle;
  }

  Future<PkBattleRemote?> inviteRoom({
    required String roomId,
    String? alternateRoomId,
    required String opponentRoomId,
    String? alternateOpponentRoomId,
    int durationSeconds = 180,
  }) async {
    final stale = state;
    if (stale != null && stale.isEnded) clear();

    final battle = await _api.inviteVoiceRoom(
      roomId: roomId,
      alternateRoomId: alternateRoomId,
      opponentRoomId: opponentRoomId,
      alternateOpponentRoomId: alternateOpponentRoomId,
      durationSeconds: durationSeconds,
    );
    if (battle != null) _apply(battle, 'pk:invite');
    return battle;
  }

  Future<PkBattleRemote?> inviteStream({
    required String streamId,
    required String opponentStreamId,
  }) async {
    final battle = await _api.streamPkAction(
      streamId: streamId,
      action: 'create',
      opponentStreamId: opponentStreamId,
    );
    if (battle != null) _apply(battle, 'pk:invite');
    return battle;
  }

  /// Sesli oda: `roomId` zorunlu. Canlı yayın: `streamId` verin.
  Future<PkBattleRemote?> accept(
    String battleId, {
    String? roomId,
    String? alternateRoomId,
    String? streamId,
  }) async {
    final PkBattleRemote? battle;
    if (roomId != null && roomId.trim().isNotEmpty) {
      battle = await _api.acceptBattle(
        battleId,
        roomId: roomId,
        alternateRoomId: alternateRoomId,
      );
    } else if (streamId != null && streamId.trim().isNotEmpty) {
      battle = await _api.streamPkAction(
        streamId: streamId,
        action: 'accept',
        battleId: battleId,
      );
    } else {
      return null;
    }
    if (battle != null) _apply(battle, 'pk:accept');
    return battle;
  }

  Future<PkBattleRemote?> reject(
    String battleId, {
    String? roomId,
    String? alternateRoomId,
    String? streamId,
  }) async {
    final PkBattleRemote? battle;
    if (roomId != null && roomId.trim().isNotEmpty) {
      battle = await _api.rejectBattle(
        battleId,
        roomId: roomId,
        alternateRoomId: alternateRoomId,
      );
    } else if (streamId != null && streamId.trim().isNotEmpty) {
      battle = await _api.streamPkAction(
        streamId: streamId,
        action: 'reject',
        battleId: battleId,
      );
    } else {
      return null;
    }
    if (battle != null) _apply(battle, 'pk:reject');
    return battle;
  }

  Future<PkBattleRemote?> end(
    String battleId, {
    String? roomId,
    String? alternateRoomId,
    String? streamId,
  }) async {
    final PkBattleRemote? battle;
    if (roomId != null && roomId.trim().isNotEmpty) {
      battle = await _api.endBattle(
        battleId,
        roomId: roomId,
        alternateRoomId: alternateRoomId,
      );
    } else if (streamId != null && streamId.trim().isNotEmpty) {
      battle = await _api.streamPkAction(
        streamId: streamId,
        action: 'end',
        battleId: battleId,
      );
    } else {
      return null;
    }
    if (battle != null) _apply(battle, 'pk:end');
    return battle;
  }

  void connectSocket({
    String? roomId,
    String? alternateRoomId,
    String? streamId,
    String? battleId,
  }) {
    _socket.connect(
      roomId: roomId,
      alternateRoomId: alternateRoomId,
      streamId: streamId,
      battleId: battleId ?? state?.id,
      onUpdate: (battle, event) => _apply(battle, event),
      accessToken: () => _tokens.readAccess(),
    );
  }

  void disconnectSocket() => _socket.disconnect();

  void _apply(PkBattleRemote battle, String event) {
    state = battle;
    ref.read(pkBattleProvider.notifier).applyRemoteBattle(battle);
    if (battle.isEnded && (event == 'pk:end' || event == 'pk:winner')) {
      disconnectSocket();
    }
  }

  void clear() {
    state = null;
    disconnectSocket();
  }
}

final pkBattleRemoteProvider =
    NotifierProvider<PkBattleRemoteController, PkBattleRemote?>(
  PkBattleRemoteController.new,
);

/// PK geçmişi listesi.
final pkHistoryProvider =
    FutureProvider.family<List<PkBattleRemote>, String?>((ref, battleType) async {
  final api = ref.watch(pkBattleRemoteDataSourceProvider);
  return api.fetchHistory(battleType: battleType);
});
