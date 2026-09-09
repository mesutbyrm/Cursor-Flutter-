import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/auth/bot_account_guard.dart';
import '../../../../core/auth/bot_account_provider.dart';
import '../../domain/pk/pk_unified_bridge.dart';
import '../../../voice_hub/domain/pk/pk_battle_remote_models.dart';
import '../../../voice_hub/presentation/providers/pk_battle_remote_provider.dart';

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

  @override
  LiveVideoPkState build(String streamId) {
    ref.onDispose(() => _poll?.cancel());
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
    // Canlı 1v1 PK — tek kaynak: GET /api/video-streams/{id}/pk-battle
    try {
      final api = ref.read(pkBattleRemoteDataSourceProvider);
      final remote = await api.fetchStreamBattle(arg);
      if (remote != null && !remote.isEnded) {
        final map = pkBattleRemoteToBattleMap(remote, myStreamId: arg);
        state = state.copyWith(
          battle: map,
          unifiedMatchId: remote.effectiveId,
          clearError: true,
        );
        if (remote.isActive) {
          _startPolling();
        } else {
          _stopPolling();
        }
        return;
      }
    } catch (e) {
      state = state.copyWith(error: '$e');
    }

    _stopPolling();
    state = state.copyWith(clearBattle: true, clearUnifiedMatchId: true);
  }

  /// Kabul sonrası veya SSE'den — ana backend PK durumunu yeniler.
  Future<void> ingestRemoteBattle([String? battleId]) async {
    await refresh();
  }

  void applyRemoteBattle(Map<String, dynamic> battle) {
    final status = battle['status']?.toString() ?? '';
    // Pending davet split ekranı açmaz; yalnızca kabul sonrası aktif senkron.
    if (status == 'pending' || status == 'invited') {
      state = state.copyWith(battle: battle, clearError: true);
      return;
    }
    final matchId = battle['id']?.toString() ?? battle['battleId']?.toString();
    state = state.copyWith(
      battle: battle,
      unifiedMatchId: matchId ?? state.unifiedMatchId,
      clearError: true,
    );
    if (state.isUnified && matchId != null && matchId.isNotEmpty) {
      _stopPolling();
    }
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
      state = state.copyWith(loading: false, error: 'PK oluşturulamadı');
    } catch (e) {
      state = state.copyWith(loading: false, error: '$e');
    }
  }

  Future<void> accept() => _action('accept');
  Future<void> reject() => _action('reject');
  Future<void> cancel() => _action('cancel');
  Future<void> end() => _action('end');

  Future<void> _action(String action) async {
    state = state.copyWith(loading: true, clearError: true);
    try {
      final api = ref.read(pkBattleRemoteDataSourceProvider);
      final battleId = state.unifiedMatchId ?? state.battle?['id']?.toString();
      if (battleId == null || battleId.isEmpty) {
        state = state.copyWith(loading: false, error: 'PK bulunamadı');
        return;
      }
      PkBattleRemote? remote;
      switch (action) {
        case 'accept':
          remote = await api.streamPkAction(
            streamId: arg,
            action: 'accept',
            battleId: battleId,
          );
        case 'reject':
          remote = await api.streamPkAction(
            streamId: arg,
            action: 'reject',
            battleId: battleId,
          );
        case 'cancel':
          remote = await api.streamPkAction(
            streamId: arg,
            action: 'cancel',
            battleId: battleId,
          );
        case 'end':
          remote = await api.streamPkAction(
            streamId: arg,
            action: 'end',
            battleId: battleId,
          );
      }
      if (remote != null) {
        state = state.copyWith(
          battle: pkBattleRemoteToBattleMap(remote, myStreamId: arg),
          unifiedMatchId: remote.effectiveId,
          loading: false,
        );
        if (remote.isEnded) {
          _stopPolling();
          state = state.copyWith(clearBattle: true, clearUnifiedMatchId: true);
        }
        return;
      }
      state = state.copyWith(loading: false, error: 'PK işlemi başarısız');
    } catch (e) {
      state = state.copyWith(loading: false, error: '$e');
    }
  }
}

final liveVideoPkProvider = NotifierProvider.autoDispose
    .family<LiveVideoPkNotifier, LiveVideoPkState, String>(
  LiveVideoPkNotifier.new,
);
