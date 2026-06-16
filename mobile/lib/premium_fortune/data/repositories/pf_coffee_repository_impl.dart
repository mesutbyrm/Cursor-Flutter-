import '../../core/config/pf_config.dart';
import '../../core/errors/pf_failure.dart';
import '../../core/result/pf_result.dart';
import '../../domain/entities/pf_coffee_reading.dart';
import '../../domain/repositories/pf_coffee_repository.dart';
import '../../domain/repositories/pf_wallet_repository.dart';
import '../datasources/pf_coffee_datasource.dart';

class PfCoffeeRepositoryImpl implements PfCoffeeRepository {
  PfCoffeeRepositoryImpl(this._coffee, this._wallet);

  final PfCoffeeDatasource _coffee;
  final PfWalletRepository _wallet;

  @override
  Future<PfResult<List<PfCoffeeReading>>> getHistory(String userId) =>
      _guard(() => _coffee.getHistory(userId));

  @override
  Future<PfResult<PfCoffeeReading>> analyzePhoto({
    required String userId,
    required String localImagePath,
  }) async {
    try {
      final spend = await _wallet.spendCredits(
        userId: userId,
        amount: PfConfig.coffeeReadingCost,
        description: 'Kahve falı',
      );
      if (spend.isFailure) return PfError(spend.failureOrNull!);

      final reading = await _coffee.analyzePhoto(
        userId: userId,
        localImagePath: localImagePath,
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
