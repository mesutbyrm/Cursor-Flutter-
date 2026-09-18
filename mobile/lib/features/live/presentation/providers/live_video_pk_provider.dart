import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/auth/bot_account_guard.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/auth/bot_account_provider.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../domain/pk/live_pk_invite_helper.dart';
import '../../domain/pk/live_pk_event_dedup.dart';
import '../../domain/pk/live_pk_ingest.dart';
import 'live_pk_score_burst_provider.dart';
import '../../domain/pk/live_pk_broadcast_stage.dart';
import '../../domain/pk/pk_status_helper.dart';
import '../../domain/pk/pk_unified_bridge.dart';
import 'live_pk_action_lock_provider.dart';
import '../../../voice_hub/domain/pk/pk_battle_remote_models.dart';
import '../../../voice_hub/presentation/providers/pk_battle_remote_provider.dart';
import 'pk_session_phase_provider.dart';
import '../navigation/live_pk_home_transition_bridge.dart';

class LiveVideoPkState {
  const LiveVideoPkState({
    this.battle,
    this.unifiedMatchId,
    this.loading = false,
    this.error,
  });

  final Map<String, dynamic>? battle;
  final String? unifiedMatchId;
  final bool loading;
  final String? error;

  String get status => battle?['status']?.toString() ?? '';

  bool get isUnified => battle?['unifiedPk'] == true;

  bool get isOpponent => battle?['isOpponent'] == true;

  int get leftScore {
    final v = battle?['score1'] ?? battle?['leftScore'];
    return v is num ? v.toInt() : 0;
  }

  int get rightScore {
    final v = battle?['score2'] ?? battle?['rightScore'];
    return v is num ? v.toInt() : 0;
  }

  LiveVideoPkState copyWith({
    Map<String, dynamic>? battle,
    String? unifiedMatchId,
    bool? loading,
    String? error,
    bool clearError = false,
    bool clearBattle = false,
    bool clearUnifiedMatchId = false,
  }) {
    return LiveVideoPkState(
      battle: clearBattle ? null : (battle ?? this.battle),
      unifiedMatchId:
          clearUnifiedMatchId ? null : (unifiedMatchId ?? this.unifiedMatchId),
      loading: loading ?? this.loading,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class LiveVideoPkNotifier extends AutoDisposeFamilyNotifier<LiveVideoPkState, String> {
  Timer? _poll;
  Timer? _endedCleanup;
  String? _lastIngestFingerprint;
  final _eventDedup = LivePkEventDedup();

  @override
  LiveVideoPkState build(String streamId) {
    ref.onDispose(() {
      _poll?.cancel();
      _endedCleanup?.cancel();
    });
    Future.microtask(() => refresh());
    return const LiveVideoPkState();
  }

  void _startPolling() {
    _poll?.cancel();
    _poll = Timer.periodic(const Duration(seconds: 15), (_) {
      if (state.battle == null ||
          state.status == 'completed' ||
          state.status == 'ended') {
        _poll?.cancel();
        return;
      }
      refresh();
    });
  }

  void _stopPolling() {
    _poll?.cancel();
    _poll = null;
  }

  Future<void> refresh() async {
    // Canlı 1v1 PK — GET stream battle; yoksa /api/pk/me/invites yedek.
    try {
      final api = ref.read(pkBattleRemoteDataSourceProvider);
      var remote = await api.fetchStreamBattle(arg);
      if (remote == null || remote.isEnded) {
        final userId = ref.read(authControllerProvider).valueOrNull?.id ?? '';
        if (userId.isNotEmpty) {
          final invites = await api.fetchMyInvites();
          for (final inv in invites) {
            if (!inv.isPending || inv.isEnded || !isLiveStreamPkBattle(inv)) {
              continue;
            }
            if (isLivePkInviteRecipientBattle(
                  inv,
                  myUserId: userId,
                  myStreamId: arg,
                ) ||
                inv.opponentLiveStreamId?.trim() == arg ||
                inv.liveStreamId?.trim() == arg) {
              remote = inv;
              break;
            }
          }
        }
      }
      if (remote != null) {
        final map = _mergeBattleMap(
          pkBattleRemoteToBattleMap(remote, myStreamId: arg),
          previous: state.battle,
        );
        if (!remote.isEnded || isLivePkEndedStatus(remote.status)) {
          state = state.copyWith(
            battle: map,
            unifiedMatchId: remote.effectiveId,
            clearError: true,
          );
          if (isLivePkActiveStatus(remote.status)) {
            _startPolling();
          } else {
            _stopPolling();
            if (isLivePkEndedStatus(remote.status)) {
              _scheduleEndedCleanup(remote.effectiveId);
            }
          }
          return;
        }
      }
    } catch (e) {
      state = state.copyWith(error: '$e');
      if (isLivePkBroadcastStage(state.battle, state.status)) {
        return;
      }
    }

    _stopPolling();
    if (isPkInvitePendingStatus(state.status)) {
      return;
    }
    if (isLivePkBroadcastStage(state.battle, state.status)) {
      return;
    }
    state = state.copyWith(clearBattle: true, clearUnifiedMatchId: true);
  }

  /// Skor güncellemesi — tam `refresh` PK ekranını düşürmez.
  /// Sunucu skor güncellemesi gelene kadar yalnızca görsel burst; otorite sunucuda.
  void applyLocalScoreDelta({required String side, required int amount}) {
    if (amount <= 0) return;
    final b = state.battle;
    if (b == null) return;
    final next = Map<String, dynamic>.from(b);
    final isLeft = side == 'score1' || side == 'left';
    final key = isLeft ? 'score1' : 'score2';
    final altLeft = 'leftScore';
    final altRight = 'rightScore';
    final cur = int.tryParse('${next[key] ?? (isLeft ? next[altLeft] : next[altRight]) ?? 0}') ?? 0;
    next[key] = cur + amount;
    if (isLeft) {
      next[altLeft] = next[key];
      next['challengerScore'] = next[key];
    } else {
      next[altRight] = next[key];
      next['opponentScore'] = next[key];
    }
    state = state.copyWith(battle: next, clearError: true);
  }

  Map<String, dynamic> _mergeBattleMap(
    Map<String, dynamic> incoming,
    {Map<String, dynamic>? previous,
  }) {
    if (previous == null) return incoming;
    final out = Map<String, dynamic>.from(previous);
    for (final e in incoming.entries) {
      final v = e.value;
      if (v == null) continue;
      if (v is String && v.trim().isEmpty) continue;
      out[e.key] = v;
    }
    for (final key in [
      'liveStreamId',
      'hostStreamId',
      'opponentLiveStreamId',
      'opponentStreamId',
      'endsAt',
      'startedAt',
    ]) {
      final inc = incoming[key]?.toString().trim() ?? '';
      if (inc.isEmpty) continue;
      out[key] = incoming[key];
    }
    _ensurePkEndsAt(out);
    return out;
  }

  void _ensurePkEndsAt(Map<String, dynamic> battle) {
    final endsRaw = battle['endsAt']?.toString().trim() ?? '';
    if (endsRaw.isNotEmpty && DateTime.tryParse(endsRaw) != null) return;
    final started = DateTime.tryParse(battle['startedAt']?.toString() ?? '');
    if (started == null) return;
    final dur = int.tryParse(
          '${battle['durationSeconds'] ?? battle['duration'] ?? 180}',
        ) ??
        180;
    battle['endsAt'] =
        started.toUtc().add(Duration(seconds: dur)).toIso8601String();
  }

  /// Kabul sonrası veya SSE'den — ana backend PK durumunu yeniler.
  Future<void> ingestRemoteBattle([String? battleId]) async {
    await refresh();
  }

  void applyRemoteBattle(Map<String, dynamic> battle) {
    if (!_eventDedup.shouldProcess(battle)) {
      return;
    }
    final fp = livePkBattleIngestFingerprint(battle);
    if (fp.isNotEmpty && fp == _lastIngestFingerprint) {
      return;
    }
    _lastIngestFingerprint = fp;

    final status = battle['status']?.toString() ?? '';
    // Pending davet split ekranı açmaz; yalnızca kabul sonrası aktif senkron.
    final merged = _mergeBattleMap(battle, previous: state.battle);
    if (isPkInvitePendingStatus(status)) {
      state = state.copyWith(battle: merged, clearError: true);
      syncLivePkHomeTransitionFromBattle(ref, battle: merged, streamId: arg);
      _stopPolling();
      return;
    }
    if (!isLivePkActiveStatus(status)) {
      state = state.copyWith(battle: merged, clearError: true);
      syncLivePkHomeTransitionFromBattle(ref, battle: merged, streamId: arg);
      _stopPolling();
      if (isLivePkEndedStatus(status)) {
        _scheduleEndedCleanup(merged['id']?.toString() ?? '');
      }
      return;
    }
    final matchId = merged['id']?.toString() ?? merged['battleId']?.toString();
    state = state.copyWith(
      battle: merged,
      unifiedMatchId: matchId ?? state.unifiedMatchId,
      clearError: true,
    );
    syncLivePkHomeTransitionFromBattle(ref, battle: merged, streamId: arg);
    if (state.isUnified && matchId != null && matchId.isNotEmpty) {
      _stopPolling();
    }
  }

  void _scheduleEndedCleanup(String battleId) {
    final bid = battleId.trim();
    if (bid.isEmpty) return;
    _endedCleanup?.cancel();
    _endedCleanup = Timer(const Duration(seconds: 4), () {
      dismissEndedOverlay(expectedBattleId: bid);
    });
  }

  /// PK sonuç ekranından sonra split'i kapatır (sunucu zaten `ended` döndü).
  void dismissEndedOverlay({String? expectedBattleId}) {
    final currentId = state.battle?['id']?.toString() ?? '';
    if (!isLivePkEndedStatus(state.status)) return;
    if (expectedBattleId != null &&
        expectedBattleId.trim().isNotEmpty &&
        currentId != expectedBattleId.trim()) {
      return;
    }
    _endedCleanup?.cancel();
    _eventDedup.clear();
    _lastIngestFingerprint = null;
    ref.read(livePkScoreBurstProvider(arg).notifier).reset();
    state = state.copyWith(clearBattle: true, clearUnifiedMatchId: true);
    ref.read(livePkHomeTransitionProvider.notifier).reset();
  }

  Future<void> create({String? opponentStreamId, String? targetStreamId}) async {
    if (ref.read(isBotAccountProvider)) {
      state = state.copyWith(
        loading: false,
        error: BotAccountGuard.blockedMessage('PK başlatma'),
      );
      return;
    }
    state = state.copyWith(loading: true, clearError: true);
    final opponent = targetStreamId ?? opponentStreamId;
    try {
      if (opponent != null && opponent.isNotEmpty) {
        final api = ref.read(pkBattleRemoteDataSourceProvider);
        final remote = await api.streamPkAction(
          streamId: arg,
          action: 'create',
          opponentStreamId: opponent,
          duration: 180,
        );
        if (remote != null) {
          state = state.copyWith(
            battle: pkBattleRemoteToBattleMap(remote, myStreamId: arg),
            unifiedMatchId: remote.effectiveId,
            loading: false,
          );
          return;
        }
      }
      state = state.copyWith(
        loading: false,
        error: 'PK oluşturulamadı. Sunucu yanıt vermedi; bağlantınızı kontrol edin.',
      );
    } catch (e) {
      state = state.copyWith(
        loading: false,
        error: ApiException.userMessage(e),
      );
    }
  }

  Future<void> accept() => _action('accept');
  Future<void> reject() => _action('reject');
  Future<void> cancel() => _action('cancel');
  Future<void> end() => _action('end');

  Future<void> _action(String action) async {
    final api = ref.read(pkBattleRemoteDataSourceProvider);
    final battleId = state.unifiedMatchId ?? state.battle?['id']?.toString();
    if (battleId == null || battleId.isEmpty) {
      ref.read(pkSessionPhaseProvider.notifier).reset();
      state = state.copyWith(loading: false, error: 'PK bulunamadı');
      return;
    }
    final lock = ref.read(livePkActionLockProvider.notifier);
    if (!lock.tryAcquire(battleId, action)) {
      return;
    }
    state = state.copyWith(loading: true, clearError: true);
    try {
      PkBattleRemote? remote;
      switch (action) {
        case 'accept':
          remote = await api.streamPkAction(
            streamId: arg,
            action: 'accept',
            battleId: battleId,
          );
          break;
        case 'reject':
          remote = await api.streamPkAction(
            streamId: arg,
            action: 'reject',
            battleId: battleId,
          );
          break;
        case 'cancel':
          remote = await api.streamPkAction(
            streamId: arg,
            action: 'cancel',
            battleId: battleId,
          );
          break;
        case 'end':
          remote = await api.streamPkAction(
            streamId: arg,
            action: 'end',
            battleId: battleId,
          );
          break;
      }
      if (remote != null) {
        state = state.copyWith(
          battle: pkBattleRemoteToBattleMap(remote, myStreamId: arg),
          unifiedMatchId: remote.effectiveId,
          loading: false,
        );
        if (remote.isEnded) {
          _stopPolling();
          _scheduleEndedCleanup(remote.effectiveId);
        }
        return;
      }
      ref.read(pkSessionPhaseProvider.notifier).reset();
      state = state.copyWith(loading: false, error: 'PK işlemi başarısız');
    } catch (e) {
      ref.read(pkSessionPhaseProvider.notifier).reset();
      state = state.copyWith(loading: false, error: '$e');
    } finally {
      lock.release(battleId, action);
    }
  }
}

final liveVideoPkProvider = NotifierProvider.autoDispose
    .family<LiveVideoPkNotifier, LiveVideoPkState, String>(
  LiveVideoPkNotifier.new,
);
