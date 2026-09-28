import '../../domain/entities/sports_prediction_entity.dart';
import '../../domain/repositories/sports_repository.dart';
import '../datasources/sports_datasource.dart';

class SportsRepositoryImpl implements SportsRepository {
  final SportsDataSource _dataSource;

  SportsRepositoryImpl({required SportsDataSource dataSource})
      : _dataSource = dataSource;

  @override
  Future<List<FootballMatch>> getFootballMatches() async {
    final dtos = await _dataSource.getFootballMatches();
    return dtos.map((dto) => dto.toDomain()).toList();
  }

  @override
  Future<FootballMatch> getMatchDetail(String matchId) async {
    final dto = await _dataSource.getMatchDetail(matchId);
    return dto.toDomain();
  }

  @override
  Future<Bet> placeBet(
    String matchId,
    String prediction,
    double amount,
  ) async {
    final dto = await _dataSource.placeBet(matchId, prediction, amount);
    return dto.toDomain();
  }

  @override
  Future<List<Bet>> getUserBets() async {
    final dtos = await _dataSource.getUserBets();
    return dtos.map((dto) => dto.toDomain()).toList();
  }

  @override
  Future<List<LeaderboardEntry>> getLeaderboard({int limit = 50}) async {
    final dtos = await _dataSource.getLeaderboard(limit: limit);
    return dtos.map((dto) => dto.toDomain()).toList();
  }

  @override
  Future<void> cancelBet(String betId) async {
    await _dataSource.cancelBet(betId);
  }
}
