import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/dio_provider.dart';
import '../../../../core/network/pk_event_log.dart';
import '../../../../core/network/token_storage.dart';
import '../../../live/domain/pk/pk_session_phase.dart';
import '../../../live/presentation/providers/pk_session_phase_provider.dart';
import '../../data/datasources/pk_battle_remote_datasource.dart';
import '../../data/services/pk_battle_socket_service.dart';
import '../../domain/pk/pk_battle_remote_models.dart';
import '../../domain/pk/pk_duration_options.dart';
import 'pk_battle_provider.dart';

final pkBattleRemoteDataSourceProvider = Provider<PkBattleRemoteDataSource>((ref) {
  return PkBattleRemoteDataSource(ref.watch(dioProvider));
});

/// Sunucu PK senkronu — REST + Socket.IO yedek; odadayken SSE birincil.
class PkBattleRemoteController extends Notifier<PkBattleRemote?> {
  PkBattleRemoteDataSource get _api => ref.read(pkBattleRemoteDataSourceProvider);

  PkBattleSocketService? _socket;
  PkBattleSocketService? _ownedRoomsSocket;

  @override
  PkBattleRemote? build() {
    ref.onDispose(() {
      disconnectSocket();
      disconnectOwnedRoomsSocket();
    });
    return null;
  }

  Future<PkBattleRemote?> loadRoomBattle(String roomId, {String? alternateRoomId}) async {
    final battle = await _api.fetchRoomBattle(
      roomId,
      alternateRoomId: alternateRoomId,
    );
    if (battle != null) _apply(battle, 'load');
    return battle;
  }

  /// Sunucudaki askıda / bitmemiş PK kaydını temizler; davet öncesi çağırın.
  Future<bool> prepareRoomForInvite({
    required String roomId,
    String? alternateRoomId,
  }) async {
    final stale = state;
    if (stale != null && stale.isEnded) clear();

    final battle = await _api.fetchRoomBattle(
      roomId,
      alternateRoomId: alternateRoomId,
    );
    if (battle == null) {
      clear();
      return true;
    }
    if (battle.isEnded) {
      clear();
      return true;
    }
    if (battle.id.isEmpty) {
      clear();
      return true;
    }
    try {
      await end(
        battle.id,
        roomId: roomId,
        alternateRoomId: alternateRoomId,
      );
    } catch (_) {}
    clear();
    return true;
  }

  Future<PkBattleRemote?> loadStreamBattle(String streamId) async {
    final battle = await _api.fetchStreamBattle(streamId);
    if (battle != null) _apply(battle, 'load');
    return battle;
  }

  Future<PkBattleRemote?> inviteRoom({
    required String roomId,
    String? alternateRoomId,
    required String guestUserId,
    String? opponentRoomId,
    int durationSeconds = 180,
  }) async {
    final stale = state;
    if (stale != null && stale.isEnded) clear();

    final battle = await _api.inviteVoiceRoom(
      roomId: roomId,
      alternateRoomId: alternateRoomId,
      guestUserId: guestUserId,
      opponentRoomId: opponentRoomId,
      durationSeconds: durationSeconds,
    );
    if (battle != null) {
      PkEventLog.requestSuccess(battleId: battle.id);
      _apply(battle, 'pk:invite');
    }
    return battle;
  }

  Future<PkBattleRemote?> inviteStream({
    required String streamId,
    required String opponentStreamId,
    int durationSeconds = pkDefaultDurationSeconds,
  }) async {
    final battle = await _api.streamPkAction(
      streamId: streamId,
      action: 'create',
      opponentStreamId: opponentStreamId,
      duration: durationSeconds,
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
    PkEventLog.acceptStart(inviteId: battleId);
    ref.read(pkSessionPhaseProvider.notifier).transitionTo(PkSessionPhase.accepting);
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
    if (battle != null) {
      PkEventLog.acceptSuccess(battleId: battle.id);
      _apply(battle, 'pk:accept');
    }
    return battle;
  }

  Future<PkBattleRemote?> reject(
    String battleId, {
    String? roomId,
    String? alternateRoomId,
    String? streamId,
  }) async {
    PkEventLog.reject(inviteId: battleId);
    ref.read(pkSessionPhaseProvider.notifier).transitionTo(PkSessionPhase.rejecting);
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
    if (battle != null) {
      _apply(battle, 'pk:reject');
    }
    return battle;
  }

  Future<PkBattleRemote?> end(
    String battleId, {
    String? roomId,
    String? alternateRoomId,
    String? streamId,
  }) async {
    PkEventLog.ending(battleId: battleId);
    ref.read(pkSessionPhaseProvider.notifier).transitionTo(PkSessionPhase.ending);
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
    if (battle != null) {
      PkEventLog.ended(battleId: battleId);
      _apply(battle, 'pk:end');
    }
    return battle;
  }

  /// Sahip olunan odalar için global PK socket — polling yerine anlık davet.
  void connectOwnedRooms(List<String> roomKeys) {
    final keys = roomKeys
        .map((k) => k.trim())
        .where((k) => k.isNotEmpty)
        .toSet()
        .toList(growable: false);
    if (keys.isEmpty) return;

    _ownedRoomsSocket ??= PkBattleSocketService();
    final storage = ref.read(tokenStorageProvider);
    _ownedRoomsSocket!.connect(
      roomKeys: keys,
      onUpdate: (battle, event) => _apply(battle, event),
      accessToken: storage.readAccess,
    );
  }

  void disconnectOwnedRoomsSocket() {
    _ownedRoomsSocket?.disconnect();
    _ownedRoomsSocket = null;
  }

  /// Socket.IO PK kanalı — web ile aynı olaylar; SSE yedek / oda dışı skor.
  void connectSocket({
    String? roomId,
    String? alternateRoomId,
    String? streamId,
    String? battleId,
  }) {
    final hasRoom = roomId != null && roomId.trim().isNotEmpty;
    final hasStream = streamId != null && streamId.trim().isNotEmpty;
    if (!hasRoom && !hasStream) return;

    _socket ??= PkBattleSocketService();
    final storage = ref.read(tokenStorageProvider);
    _socket!.connect(
      roomId: roomId,
      alternateRoomId: alternateRoomId,
      streamId: streamId,
      battleId: battleId,
      onUpdate: (battle, event) => _apply(battle, event),
      accessToken: storage.readAccess,
    );
  }

  /// Socket.IO bağlantısını kapat.
  void disconnectSocket() {
    _socket?.disconnect();
    _socket = null;
  }

  /// Oda SSE üzerinden gelen PK güncellemesi — socket bağlantısı gerekmez.
  void ingestSseBattle(PkBattleRemote battle) {
    _apply(battle, 'sse:pk');
  }

  void _apply(PkBattleRemote battle, String event) {
    state = battle;
    _syncPhase(battle, event);
    ref.read(pkBattleProvider.notifier).applyRemoteBattle(battle);
  }

  void _syncPhase(PkBattleRemote battle, String event) {
    final phase = ref.read(pkSessionPhaseProvider.notifier);
    if (battle.isEnded) {
      if (battle.status == 'rejected') {
        phase.transitionTo(PkSessionPhase.rejected);
      } else {
        phase.transitionTo(PkSessionPhase.ended);
      }
      return;
    }
    if (battle.isActive) {
      phase.transitionTo(PkSessionPhase.connecting);
      phase.transitionTo(PkSessionPhase.active);
      return;
    }
    if (battle.isPending) {
      if (event.contains('invite')) {
        phase.transitionTo(PkSessionPhase.requesting);
      } else {
        phase.transitionTo(PkSessionPhase.incoming);
      }
    }
  }

  void clear() {
    state = null;
    ref.read(pkSessionPhaseProvider.notifier).reset();
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
