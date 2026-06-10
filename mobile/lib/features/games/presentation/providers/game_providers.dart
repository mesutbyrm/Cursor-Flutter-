import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/dio_provider.dart';
import '../../data/game_remote_datasource.dart';
import '../../domain/game_models.dart';

final gameRemoteProvider = Provider<GameRemoteDataSource>((ref) {
  return GameRemoteDataSource(ref.watch(dioProvider));
});

final gameCatalogProvider = FutureProvider<List<GameCatalogItem>>((ref) {
  return ref.watch(gameRemoteProvider).fetchCatalog();
});

final gameRoomsProvider = FutureProvider<List<GameRoomItem>>((ref) {
  return ref.watch(gameRemoteProvider).fetchRooms();
});

final gameLeaderboardProvider = FutureProvider<List<GameScoreItem>>((ref) {
  return ref.watch(gameRemoteProvider).fetchLeaderboard();
});

final gameHistoryProvider = FutureProvider<List<GameScoreItem>>((ref) {
  return ref.watch(gameRemoteProvider).fetchHistory();
});

final gameMiniScoresProvider = FutureProvider<List<GameScoreItem>>((ref) {
  return ref.watch(gameRemoteProvider).fetchMiniScores();
});

final gameProfileScoresProvider = FutureProvider<List<GameScoreItem>>((ref) {
  return ref.watch(gameRemoteProvider).fetchProfileScores();
});

final gameTournamentsProvider = FutureProvider<List<GameScoreItem>>((ref) {
  return ref.watch(gameRemoteProvider).fetchTournaments();
});

class GameRoomController
    extends
        AutoDisposeFamilyNotifier<AsyncValue<GameRoomStateSnapshot>, String> {
  Timer? _poll;

  @override
  AsyncValue<GameRoomStateSnapshot> build(String roomId) {
    ref.onDispose(() => _poll?.cancel());
    Future.microtask(() => refresh());
    _poll = Timer.periodic(
      const Duration(seconds: 5),
      (_) => refresh(silent: true),
    );
    return const AsyncValue.loading();
  }

  Future<void> refresh({bool silent = false}) async {
    if (!silent) state = const AsyncValue.loading();
    state = await AsyncValue.guard(
      () => ref.read(gameRemoteProvider).fetchRoomState(arg),
    );
  }

  Future<void> sendMove(Map<String, dynamic> move) async {
    state = await AsyncValue.guard(
      () => ref.read(gameRemoteProvider).sendMove(roomId: arg, move: move),
    );
  }

  Future<void> sendChat(String text) async {
    await ref.read(gameRemoteProvider).sendChat(roomId: arg, text: text);
    await refresh(silent: true);
  }
}

final gameRoomControllerProvider = NotifierProvider.autoDispose
    .family<GameRoomController, AsyncValue<GameRoomStateSnapshot>, String>(
      GameRoomController.new,
    );
