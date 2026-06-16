import '../../core/result/pf_result.dart';
import '../entities/pf_wallet.dart';

abstract interface class PfWalletRepository {
  Stream<int> watchCredits(String userId);
  Future<PfResult<List<PfWalletTransaction>>> getTransactions(String userId);
  Future<PfResult<void>> spendCredits({
    required String userId,
    required int amount,
    required String description,
    String? referenceId,
  });
  Future<PfResult<void>> addCredits({
    required String userId,
    required int amount,
    required PfTransactionType type,
    required String description,
    String? referenceId,
  });
  Future<PfResult<void>> redeemCoupon(String userId, String code);
  List<PfCreditPackage> getPackages();
  Future<PfResult<void>> purchasePackage({
    required String userId,
    required PfCreditPackage package,
    required String paymentProvider,
  });
}
