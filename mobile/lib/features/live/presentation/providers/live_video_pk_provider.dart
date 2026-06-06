import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/datasources/live_stream_extras_datasource.dart';
import 'live_providers.dart';

class LiveVideoPkState {
  const LiveVideoPkState({
    this.battle,
    this.loading = false,
    this.error,
  });

  final Map<String, dynamic>? battle;
  final bool loading;
  final String? error;

  String get status => battle?['status']?.toString() ?? '';

  int get leftScore {
    final v = battle?['leftScore'];
    return v is num ? v.toInt() : 0;
  }

  int get rightScore {
    final v = battle?['rightScore'];
    return v is num ? v.toInt() : 0;
  }

  LiveVideoPkState copyWith({
    Map<String, dynamic>? battle,
    bool? loading,
    String? error,
    bool clearError = false,
    bool clearBattle = false,
  }) {
    return LiveVideoPkState(
      battle: clearBattle ? null : (battle ?? this.battle),
      loading: loading ?? this.loading,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class LiveVideoPkNotifier extends AutoDisposeFamilyNotifier<LiveVideoPkState, String> {
  LiveStreamExtrasDataSource get _remote => ref.read(liveStreamExtrasProvider);

  Timer? _poll;

  @override
  LiveVideoPkState build(String streamId) {
    ref.onDispose(() => _poll?.cancel());
    Future.microtask(() => refresh());
    _startPolling();
    return const LiveVideoPkState();
  }

  void _startPolling() {
    _poll?.cancel();
    _poll = Timer.periodic(const Duration(seconds: 3), (_) => refresh());
  }

  Future<void> refresh() async {
    final battle = await _remote.fetchPkBattle(arg);
    if (battle == null && state.battle == null) return;
    state = state.copyWith(
      battle: battle,
      clearBattle: battle == null,
      clearError: true,
    );
  }

  void applyRemoteBattle(Map<String, dynamic> battle) {
    state = state.copyWith(battle: battle, clearError: true);
  }

  Future<void> create({String? opponentStreamId}) async {
    state = state.copyWith(loading: true, clearError: true);
    try {
      final battle = await _remote.pkAction(
        streamId: arg,
        action: 'create',
        opponentStreamId: opponentStreamId,
      );
      state = state.copyWith(battle: battle, loading: false);
    } catch (e) {
      state = state.copyWith(loading: false, error: '$e');
    }
  }

  Future<void> accept() => _action('accept');
  Future<void> reject() => _action('reject');
  Future<void> end() => _action('end');

  Future<void> addScore({required int score, required bool rightSide}) async {
    try {
      final battle = await _remote.pkAction(
        streamId: arg,
        action: 'score',
        score: score,
        side: rightSide ? 'right' : 'left',
      );
      state = state.copyWith(battle: battle);
    } catch (_) {}
  }

  Future<void> _action(String action) async {
    state = state.copyWith(loading: true, clearError: true);
    try {
      final battle = await _remote.pkAction(streamId: arg, action: action);
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
