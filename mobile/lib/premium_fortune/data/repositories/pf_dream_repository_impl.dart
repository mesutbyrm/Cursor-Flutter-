import '../../core/config/pf_config.dart';
import '../../core/errors/pf_failure.dart';
import '../../core/result/pf_result.dart';
import '../../domain/entities/pf_dream_reading.dart';
import '../../domain/repositories/pf_dream_repository.dart';
import '../../domain/repositories/pf_wallet_repository.dart';
import '../datasources/pf_dream_datasource.dart';

class PfDreamRepositoryImpl implements PfDreamRepository {
  PfDreamRepositoryImpl(this._dream, this._wallet);

  final PfDreamDatasource _dream;
  final PfWalletRepository _wallet;

  @override
  Future<PfResult<List<PfDreamReading>>> getHistory(String userId) =>
      _guard(() => _dream.getHistory(userId));

  @override
  Future<PfResult<PfDreamReading>> interpretDream({
    required String userId,
    required String dreamText,
  }) async {
    try {
      final spend = await _wallet.spendCredits(
        userId: userId,
        amount: PfConfig.dreamReadingCost,
        description: 'Rüya tabiri',
      );
      if (spend.isFailure) return PfError(spend.failureOrNull!);

      final reading = await _dream.interpretDream(
        userId: userId,
        dreamText: dreamText,
      );
      return PfSuccess(reading);
    } on PfFailure catch (e) {
      return PfError(e);
    } catch (e) {
      return PfError(PfAiFailure(e.toString()));
    }
  }

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
