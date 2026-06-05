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
  }) {
    return LiveVideoPkState(
      battle: battle ?? this.battle,
      loading: loading ?? this.loading,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class LiveVideoPkNotifier extends AutoDisposeFamilyNotifier<LiveVideoPkState, String> {
  LiveStreamExtrasDataSource get _remote => ref.read(liveStreamExtrasProvider);

  @override
  LiveVideoPkState build(String streamId) {
    Future.microtask(() => refresh());
    return const LiveVideoPkState();
  }

  Future<void> refresh() async {
    final battle = await _remote.fetchPkBattle(arg);
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
    final battle = await _remote.pkAction(
      streamId: arg,
      action: 'score',
      score: score,
      side: rightSide ? 'right' : 'left',
    );
    state = state.copyWith(battle: battle);
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
