import '../../core/config/pf_config.dart';
import '../../core/errors/pf_failure.dart';
import '../../core/result/pf_result.dart';
import '../../domain/entities/pf_tarot_reading.dart';
import '../../domain/repositories/pf_tarot_repository.dart';
import '../../domain/repositories/pf_wallet_repository.dart';
import '../datasources/pf_tarot_datasource.dart';

class PfTarotRepositoryImpl implements PfTarotRepository {
  PfTarotRepositoryImpl(this._tarot, this._wallet);

  final PfTarotDatasource _tarot;
  final PfWalletRepository _wallet;

  @override
  List<PfTarotCard> getDeck() => _tarot.getDeck();

  @override
  Future<PfResult<List<PfTarotReading>>> getHistory(String userId) =>
      _guard(() => _tarot.getHistory(userId));

  @override
  Future<PfResult<PfTarotReading>> createReading({
    required String userId,
    required PfTarotMode mode,
    required List<String> selectedCardIds,
  }) async {
    try {
      final spend = await _wallet.spendCredits(
        userId: userId,
        amount: PfConfig.tarotReadingCost,
        description: 'Tarot falı (${mode.name})',
      );
      if (spend.isFailure) return PfError(spend.failureOrNull!);

      final reading = await _tarot.createReading(
        userId: userId,
        mode: mode,
        selectedCardIds: selectedCardIds,
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
