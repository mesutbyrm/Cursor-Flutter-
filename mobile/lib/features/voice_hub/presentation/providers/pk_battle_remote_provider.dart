import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/dio_provider.dart';
import '../../../../core/network/pk_event_log.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../live/domain/entities/voice_room_entity.dart';
import '../../../live/domain/pk/live_pk_invite_helper.dart';
import '../../../live/domain/pk/pk_session_phase.dart';
import '../../../live/domain/pk/pk_unified_bridge.dart';
import '../../../live/presentation/providers/live_pk_invite_signal_provider.dart';
import '../../../live/presentation/providers/live_providers.dart';
import '../../../live/presentation/providers/live_video_pk_provider.dart';
import '../../../live/presentation/providers/pk_session_phase_provider.dart';
import '../../data/datasources/pk_battle_remote_datasource.dart';
import '../../domain/pk/pk_battle_remote_models.dart';
import '../../domain/pk/pk_duration_options.dart';
import '../../domain/pk/pk_opponent_room_filter.dart';
import 'pk_battle_provider.dart';
import 'voice_room_session_registry.dart';

final pkBattleRemoteDataSourceProvider = Provider<PkBattleRemoteDataSource>((ref) {
  return PkBattleRemoteDataSource(ref.watch(dioProvider));
});

/// Sunucu PK senkronu — REST + SSE; odadayken SSE birincil.
class PkBattleRemoteController extends Notifier<PkBattleRemote?> {
  PkBattleRemoteDataSource get _api => ref.read(pkBattleRemoteDataSourceProvider);
  Timer? _activePoll;
  String? _pollRoomId;
  String? _pollAltRoomId;

  @override
  PkBattleRemote? build() {
    ref.onDispose(() => _activePoll?.cancel());
    return null;
  }

  void _scheduleActivePoll() {
    _activePoll?.cancel();
    final battle = state;
    if (battle == null || !battle.isActive) return;
    final roomId = _pollRoomId?.trim() ?? '';
    if (roomId.isEmpty) return;
    _activePoll = Timer.periodic(const Duration(seconds: 4), (_) {
      unawaited(loadRoomBattle(roomId, alternateRoomId: _pollAltRoomId));
    });
  }

  Future<PkBattleRemote?> loadRoomBattle(String roomId, {String? alternateRoomId}) async {
    _pollRoomId = roomId;
    _pollAltRoomId = alternateRoomId;
    final battle = await _api.fetchRoomBattle(
      roomId,
      alternateRoomId: alternateRoomId,
    );
    if (battle != null) {
      _apply(battle, 'load');
    } else {
      _activePoll?.cancel();
    }
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
    String guestUserId = '',
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
      if (battle.isPending) {
        ref.read(livePkInviteSignalProvider.notifier).bump();
      }
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
    if (battle != null) {
      _apply(battle, 'pk:invite');
      _syncLiveVideoPk(battle);
    }
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

  /// Oda SSE üzerinden gelen PK güncellemesi.
  void ingestSseBattle(PkBattleRemote battle) {
    if (!_shouldIngestBattle(battle)) return;
    _apply(battle, 'sse:pk');
    if (battle.isPending) {
      ref.read(livePkInviteSignalProvider.notifier).bump();
    }
  }

  /// Yabancı oda PK olaylarını global state'e yazma; davet hedefi istisnası.
  bool _shouldIngestBattle(PkBattleRemote battle) {
    final user = ref.read(authControllerProvider).valueOrNull;

    if (isLiveStreamPkBattle(battle)) {
      final owned = ref.read(myOwnedLiveStreamsProvider);
      for (final stream in owned) {
        if (pkBattleBelongsToLiveStream(battle, stream.id)) return true;
        if (battle.isPending &&
            user != null &&
            isLivePkInviteRecipientBattle(
              battle,
              myUserId: user.id,
              myStreamId: stream.id,
            )) {
          return true;
        }
      }
      if (battle.isPending && user != null) {
        if (isLivePkInviteRecipientBattle(battle, myUserId: user.id)) {
          return true;
        }
      }
      return false;
    }

    final activeKey = ref.read(voiceRoomActiveLiveKeyProvider)?.trim() ?? '';
    if (activeKey.isNotEmpty) {
      final room = ref.read(voiceRoomByIdProvider(activeKey)).valueOrNull;
      if (room != null) {
        if (pkBattleBelongsToRoom(battle, room)) return true;
        if (battle.isPending &&
            user != null &&
            isPkInviteTarget(battle, room, userId: user.id)) {
          return true;
        }
      }
    }

    if (battle.isPending && user != null) {
      for (final room in ref.read(myOwnedVoiceRoomsProvider)) {
        if (isPkInviteTarget(battle, room, userId: user.id)) return true;
        if (pkBattleBelongsToRoom(battle, room)) return true;
      }
    }

    // Odada değilken yalnızca kullanıcıya yönelik pending davetler (yukarıda).
    if (activeKey.isEmpty) return false;
    if (!battle.isPending) return false;

    if (user != null) {
      final uid = user.id.trim();
      final directIds = <String?>{
        battle.guestUserId,
        battle.opponentId,
        battle.targetUserId,
        battle.opponent?.userId,
      };
      for (final id in directIds) {
        if (id != null && id.trim() == uid) return true;
      }
    }
    return false;
  }

  void _apply(PkBattleRemote battle, String event) {
    final cur = state;
    if (cur != null &&
        cur.effectiveId == battle.effectiveId &&
        cur.status == battle.status &&
        cur.challengerScore == battle.challengerScore &&
        cur.opponentScore == battle.opponentScore &&
        cur.secondsLeft == battle.secondsLeft) {
      return;
    }
    state = battle;
    _syncPhase(battle, event);
    _syncLiveVideoPk(battle);
    if (battle.isActive || battle.isEnded) {
      _syncPkBattleState(battle);
    }
    if (battle.isActive) {
      _scheduleActivePoll();
    } else {
      _activePoll?.cancel();
    }
  }

  void _syncLiveVideoPk(PkBattleRemote battle) {
    if (!isLiveStreamPkBattle(battle)) return;
    final user = ref.read(authControllerProvider).valueOrNull;
    final streamIds = <String>{
      battle.liveStreamId?.trim() ?? '',
      battle.opponentLiveStreamId?.trim() ?? '',
    };
    for (final owned in ref.read(myOwnedLiveStreamsProvider)) {
      if (pkBattleBelongsToLiveStream(battle, owned.id)) {
        streamIds.add(owned.id);
      }
    }
    for (final sid in streamIds) {
      if (sid.isEmpty) continue;
      ref.read(liveVideoPkProvider(sid).notifier).applyRemoteBattle(
            pkBattleRemoteToBattleMap(
              battle,
              myStreamId: sid,
              myUserId: user?.id,
            ),
          );
    }
  }

  void _syncPkBattleState(PkBattleRemote battle) {
    if (isLiveStreamPkBattle(battle)) return;
    final activeKey = ref.read(voiceRoomActiveLiveKeyProvider)?.trim() ?? '';
    if (activeKey.isNotEmpty) {
      final room = ref.read(voiceRoomByIdProvider(activeKey)).valueOrNull;
      if (room != null) {
        if (!pkBattleBelongsToRoom(battle, room)) return;
        ref
            .read(pkBattleProvider.notifier)
            .applyRemoteBattleForVoiceRoom(battle, room);
        return;
      }
    }
    ref.read(pkBattleProvider.notifier).applyRemoteBattle(battle);
  }

  void _syncPhase(PkBattleRemote battle, String event) {
    final phase = ref.read(pkSessionPhaseProvider.notifier);
    if (event.contains('invite') && battle.isPending) {
      phase.transitionTo(PkSessionPhase.requesting);
    }
    phase.syncFromServer(
      isEnded: battle.isEnded,
      isActive: battle.isActive,
      isPending: battle.isPending,
      status: battle.status,
    );
  }

  void clear() {
    _activePoll?.cancel();
    _pollRoomId = null;
    _pollAltRoomId = null;
    state = null;
    ref.read(pkSessionPhaseProvider.notifier).reset();
  }
}

final pkBattleRemoteProvider =
    NotifierProvider<PkBattleRemoteController, PkBattleRemote?>(
  PkBattleRemoteController.new,
);

/// Oda bağlamında görünen PK — global state yanlış oda ile karışmasın.
final pkBattleForRoomProvider = Provider.family<PkBattleRemote?, VoiceRoomEntity>(
  (ref, room) {
    final battle = ref.watch(pkBattleRemoteProvider);
    if (battle == null || battle.isEnded) return null;
    return pkBattleBelongsToRoom(battle, room) ? battle : null;
  },
);

/// PK geçmişi listesi.
final pkHistoryProvider =
    FutureProvider.family<List<PkBattleRemote>, String?>((ref, battleType) async {
  final api = ref.watch(pkBattleRemoteDataSourceProvider);
  return api.fetchHistory(battleType: battleType);
});
