import '../../core/errors/pf_failure.dart';
import '../../core/result/pf_result.dart';
import '../../domain/entities/pf_wallet.dart';
import '../../domain/repositories/pf_wallet_repository.dart';
import '../datasources/pf_wallet_datasource.dart';

class PfWalletRepositoryImpl implements PfWalletRepository {
  PfWalletRepositoryImpl(this._datasource);

  final PfWalletDatasource _datasource;

  @override
  Stream<int> watchCredits(String userId) => _datasource.watchCredits(userId);

  @override
  List<PfCreditPackage> getPackages() => _datasource.getPackages();

  @override
  Future<PfResult<List<PfWalletTransaction>>> getTransactions(String userId) =>
      _guard(() => _datasource.getTransactions(userId));

  @override
  Future<PfResult<void>> spendCredits({
    required String userId,
    required int amount,
    required String description,
    String? referenceId,
  }) =>
      _guardVoid(
        () => _datasource.spendCredits(
          userId: userId,
          amount: amount,
          description: description,
          referenceId: referenceId,
        ),
      );

  @override
  Future<PfResult<void>> addCredits({
    required String userId,
    required int amount,
    required PfTransactionType type,
    required String description,
    String? referenceId,
  }) =>
      _guardVoid(
        () => _datasource.addCredits(
          userId: userId,
          amount: amount,
          type: type,
          description: description,
          referenceId: referenceId,
        ),
      );

  @override
  Future<PfResult<void>> redeemCoupon(String userId, String code) =>
      _guardVoid(() => _datasource.redeemCoupon(userId, code));

  @override
  Future<PfResult<void>> purchasePackage({
    required String userId,
    required PfCreditPackage package,
    required String paymentProvider,
  }) =>
      _guardVoid(
        () => _datasource.purchasePackage(
          userId: userId,
          package: package,
          paymentProvider: paymentProvider,
        ),
      );

  Future<PfResult<T>> _guard<T>(Future<T> Function() action) async {
    try {
      return PfSuccess(await action());
    } on PfFailure catch (e) {
      return PfError(e);
    } catch (e) {
      return PfError(PfPaymentFailure(e.toString()));
    }
  }

  Future<PfResult<void>> _guardVoid(Future<dynamic> Function() action) async {
    try {
      await action();
      return const PfSuccess(null);
    } on PfFailure catch (e) {
      return PfError(e);
    } catch (e) {
      return PfError(PfPaymentFailure(e.toString()));
    }
  }
}
