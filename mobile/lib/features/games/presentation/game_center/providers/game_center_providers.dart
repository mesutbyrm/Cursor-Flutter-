import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../profile/presentation/providers/profile_providers.dart';
import '../../../data/game_remote_datasource.dart';
import '../../../data/repositories/game_center_repository_impl.dart';
import '../../../domain/game_center_models.dart';
import '../../../domain/game_models.dart';
import '../../../domain/repositories/game_center_repository.dart';
import '../../providers/game_providers.dart';

final gameCenterRepositoryProvider = Provider<GameCenterRepository>((ref) {
  return GameCenterRepositoryImpl(
    games: ref.watch(gameRemoteProvider),
    wallet: ref.watch(walletRemoteProvider),
  );
});

final gameCenterJetonProvider = FutureProvider<int>((ref) {
  return ref.watch(gameCenterRepositoryProvider).fetchJetonBalance();
});

final gameCenterLeaderboardProvider = FutureProvider.family<
  List<LeaderboardEntry>,
  LeaderboardPeriod
>((ref, period) {
  return ref.watch(gameCenterRepositoryProvider).fetchLeaderboard(period);
});

final gameCenterLiveRoomsProvider = FutureProvider<List<GameRoomItem>>((ref) {
  return ref.watch(gameCenterRepositoryProvider).fetchLiveRooms();
});

/// Oyun sonucu kaydet ve ilgili provider'ları yenile.
Future<void> recordGameCenterResult(
  WidgetRef ref,
  GameResultPayload payload,
) async {
  await ref.read(gameCenterRepositoryProvider).saveGameResult(payload);
  ref.invalidate(gameMiniScoresProvider);
  ref.invalidate(gameLeaderboardProvider);
  ref.invalidate(gameCenterLeaderboardProvider);
  ref.invalidate(walletBalancesProvider);
  ref.invalidate(gameCenterJetonProvider);
}

Future<void> refreshGameCenter(WidgetRef ref) async {
  ref.invalidate(gameCenterJetonProvider);
  ref.invalidate(gameCenterLiveRoomsProvider);
  ref.invalidate(gameLeaderboardProvider);
  for (final period in LeaderboardPeriod.values) {
    ref.invalidate(gameCenterLeaderboardProvider(period));
  }
  await ref.read(gameCenterJetonProvider.future);
}
