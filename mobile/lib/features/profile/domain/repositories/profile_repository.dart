import '../../../auth/domain/entities/user_entity.dart';
import '../../../wallet/domain/wallet_balances.dart';
import '../entities/jeton_package_entity.dart';
import '../entities/payment_config_entity.dart';
import '../entities/referral_info_entity.dart';

abstract class ProfileRepository {
  Future<UserEntity> getUser(String id);
  Future<void> follow(String id);
  Future<void> unfollow(String id);
}

abstract class WalletRepository {
  Future<int> coinBalance();
  Future<WalletBalances> balances();
  Future<List<JetonPackageEntity>> jetonPackages();
  Future<PaymentConfigEntity> paymentConfig();
  Future<void> submitPaymentRequest(Map<String, dynamic> body);
  Future<ReferralInfoEntity> referralInfo();
}
