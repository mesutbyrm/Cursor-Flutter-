import '../entities/sports_prediction_entity.dart';

abstract class SportsRepository {
  Future<List<FootballMatch>> getFootballMatches();
  Future<FootballMatch> getMatchDetail(String matchId);
  Future<Bet> placeBet(String matchId, String prediction, double amount);
  Future<List<Bet>> getUserBets();
  Future<List<LeaderboardEntry>> getLeaderboard({int limit = 50});
  Future<void> cancelBet(String betId);
}
