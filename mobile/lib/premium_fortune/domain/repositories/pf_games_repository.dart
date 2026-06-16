import '../../core/result/pf_result.dart';
import '../entities/pf_games.dart';

abstract interface class PfGamesRepository {
  Future<PfResult<List<PfDailyQuest>>> getDailyQuests(String userId);
  Future<PfResult<void>> completeQuest(String userId, String questId);
  Future<PfResult<int>> spinWheel(String userId);
  Future<PfResult<int>> watchAdForCredits(String userId);
  Future<PfResult<List<PfBadge>>> getBadges(String userId);
}
