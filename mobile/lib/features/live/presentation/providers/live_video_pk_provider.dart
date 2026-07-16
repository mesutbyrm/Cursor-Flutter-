import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/datasources/live_stream_extras_datasource.dart';
import '../../data/pk/pk_room_remote_datasource.dart';
import '../../domain/pk/pk_room_models.dart';
import '../../domain/pk/pk_unified_bridge.dart';
import 'live_providers.dart';
import 'live_namespace_providers.dart';
import 'pk_room_providers.dart';

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
  LiveStreamExtrasDataSource get _remote => ref.read(liveStreamExtrasProvider);
  PkRoomRemoteDataSource get _pk => ref.read(pkRoomRemoteProvider);

  Timer? _poll;
  var _sseActive = false;

  @override
  LiveVideoPkState build(String streamId) {
    ref.onDispose(() => _poll?.cancel());
    Future.microtask(() => refresh());
    return const LiveVideoPkState();
  }

  void _startPolling() {
    if (_sseActive) return;
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
    // 1) Birleşik PK API (Faz 1–3) — öncelikli.
    try {
      final unified = await _pk.activeForStream(arg);
      if (unified != null && unified.mode == PkRoomMode.oneVsOne) {
        final map = pkRoomMatchToBattleMap(unified, myStreamId: arg);
        state = state.copyWith(
          battle: map,
          unifiedMatchId: unified.id,
          clearError: true,
        );
        _sseActive = true;
        _stopPolling();
        _syncLiveSocketBattle();
        // SSE ile canlı takip (skor/süre).
        ref.read(pkRoomProvider(unified.id).notifier).adopt(unified);
        return;
      }
    } catch (_) {}

    _sseActive = false;

    // 2) Eski video-stream PK yolu (geriye dönük).
    final battle = await _remote.fetchPkBattle(arg);
    if (battle == null && state.battle == null) {
      _stopPolling();
      return;
    }
    state = state.copyWith(
      battle: battle,
      clearBattle: battle == null,
      clearUnifiedMatchId: battle == null,
      clearError: true,
    );
    _syncLiveSocketBattle();
    if (battle != null) _startPolling();
  }

  void applyRemoteBattle(Map<String, dynamic> battle) {
    final matchId = battle['id']?.toString() ?? battle['battleId']?.toString();
    state = state.copyWith(
      battle: battle,
      unifiedMatchId: matchId ?? state.unifiedMatchId,
      clearError: true,
    );
    if (state.isUnified && matchId != null && matchId.isNotEmpty) {
      _sseActive = true;
      _stopPolling();
    }
    _syncLiveSocketBattle();
  }

  void _syncLiveSocketBattle() {
    final battleId = state.unifiedMatchId ??
        state.battle?['id']?.toString() ??
        state.battle?['battleId']?.toString();
    if (battleId == null || battleId.isEmpty) return;
    ref.read(liveNamespaceSocketProvider).updateRooms(
          streamId: arg,
          battleId: battleId,
        );
  }

  Future<void> create({String? opponentStreamId, String? targetStreamId}) async {
    state = state.copyWith(loading: true, clearError: true);
    final opponent = targetStreamId ?? opponentStreamId;
    try {
      if (opponent != null && opponent.isNotEmpty) {
        final unified = await _pk.request(
          hostStreamId: arg,
          opponentStreamId: opponent,
          durationSec: 180,
        );
        if (unified != null) {
          state = state.copyWith(
            battle: pkRoomMatchToBattleMap(unified, myStreamId: arg),
            unifiedMatchId: unified.id,
            loading: false,
          );
          return;
        }
      }
      final battle = await _remote.pkAction(
        streamId: arg,
        action: 'create',
        targetStreamId: opponent,
      );
      state = state.copyWith(battle: battle, loading: false);
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
      final matchId = state.unifiedMatchId ?? state.battle?['id']?.toString();
      if (state.isUnified && matchId != null && matchId.isNotEmpty) {
        final PkRoomMatch? match;
        switch (action) {
          case 'accept':
            match = await _pk.respond(matchId, action: 'accept');
          case 'reject':
            match = await _pk.respond(matchId, action: 'reject');
          case 'cancel':
            match = await _pk.cancel(matchId);
          case 'end':
            match = await _pk.end(matchId);
          default:
            match = null;
        }
        if (match != null) {
          state = state.copyWith(
            battle: pkRoomMatchToBattleMap(match, myStreamId: arg),
            unifiedMatchId: match.id,
            loading: false,
          );
          return;
        }
      }
      final battleId = state.battle?['id']?.toString();
      final battle = await _remote.pkAction(
        streamId: arg,
        action: action,
        battleId: battleId,
      );
      state = state.copyWith(battle: battle, loading: false);
    } catch (e) {
      state = state.copyWith(loading: false, error: '$e');
    }
  }
}

final liveVideoPkProvider = NotifierProvider.autoDispose
    .family<LiveVideoPkNotifier, LiveVideoPkState, String>(
  LiveVideoPkNotifier.new,
);
