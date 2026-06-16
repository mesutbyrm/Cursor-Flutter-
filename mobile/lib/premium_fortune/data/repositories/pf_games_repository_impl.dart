import '../../core/errors/pf_failure.dart';
import '../../core/result/pf_result.dart';
import '../../domain/entities/pf_games.dart';
import '../../domain/repositories/pf_games_repository.dart';
import '../../domain/repositories/pf_wallet_repository.dart';
import '../datasources/pf_games_datasource.dart';
import '../../domain/entities/pf_wallet.dart';

class PfGamesRepositoryImpl implements PfGamesRepository {
  PfGamesRepositoryImpl(this._games, this._wallet);

  final PfGamesDatasource _games;
  final PfWalletRepository _wallet;

  @override
  Future<PfResult<List<PfDailyQuest>>> getDailyQuests(String userId) =>
      _guard(() => _games.getDailyQuests(userId));

  @override
  Future<PfResult<void>> completeQuest(String userId, String questId) async {
    await _games.completeQuest(userId, questId);
    return const PfSuccess(null);
  }

  @override
  Future<PfResult<int>> spinWheel(String userId) async {
    try {
      final reward = await _games.spinWheel(userId);
      await _wallet.addCredits(
        userId: userId,
        amount: reward,
        type: PfTransactionType.reward,
        description: 'Şans çarkı',
      );
      return PfSuccess(reward);
    } on PfFailure catch (e) {
      return PfError(e);
    }
  }

  @override
  Future<PfResult<int>> watchAdForCredits(String userId) async {
    try {
      final reward = await _games.watchAdForCredits(userId);
      await _wallet.addCredits(
        userId: userId,
        amount: reward,
        type: PfTransactionType.reward,
        description: 'Reklam izleme',
      );
      return PfSuccess(reward);
    } on PfFailure catch (e) {
      return PfError(e);
    }
  }

  @override
  Future<PfResult<List<PfBadge>>> getBadges(String userId) =>
      _guard(() => _games.getBadges(userId));

  Future<PfResult<T>> _guard<T>(Future<T> Function() action) async {
    try {
      return PfSuccess(await action());
    } on PfFailure catch (e) {
      return PfError(e);
    } catch (e) {
      return PfError(PfNetworkFailure(e.toString()));
    }
  }
}
