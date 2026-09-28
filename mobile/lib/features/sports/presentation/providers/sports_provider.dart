import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/datasources/sports_datasource.dart';
import '../../data/repositories/sports_repository_impl.dart';
import '../../domain/entities/sports_prediction_entity.dart';
import '../../domain/repositories/sports_repository.dart';
import '../../../../core/providers/dio_provider.dart';

final sportsDataSourceProvider = Provider<SportsDataSource>((ref) {
  final dio = ref.watch(dioProvider);
  return SportsDataSourceImpl(dio: dio);
});

final sportsRepositoryProvider = Provider<SportsRepository>((ref) {
  final dataSource = ref.watch(sportsDataSourceProvider);
  return SportsRepositoryImpl(dataSource: dataSource);
});

final footballMatchesProvider =
    FutureProvider<List<FootballMatch>>((ref) async {
  final repository = ref.watch(sportsRepositoryProvider);
  return repository.getFootballMatches();
});

final matchDetailProvider =
    FutureProvider.family<FootballMatch, String>((ref, matchId) async {
  final repository = ref.watch(sportsRepositoryProvider);
  return repository.getMatchDetail(matchId);
});

final userBetsProvider = FutureProvider<List<Bet>>((ref) async {
  final repository = ref.watch(sportsRepositoryProvider);
  return repository.getUserBets();
});

final leaderboardProvider = FutureProvider.family<List<LeaderboardEntry>, int>(
  (ref, limit) async {
    final repository = ref.watch(sportsRepositoryProvider);
    return repository.getLeaderboard(limit: limit);
  },
);

final selectedMatchProvider = StateProvider<FootballMatch?>((ref) => null);

final placingBetProvider = StateProvider<bool>((ref) => false);
