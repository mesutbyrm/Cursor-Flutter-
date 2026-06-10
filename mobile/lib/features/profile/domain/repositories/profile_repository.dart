import '../../../../core/pagination/paged_result.dart';
import '../../../auth/domain/entities/user_entity.dart';
import '../../../wallet/domain/cfc_payment_request_entity.dart';
import '../entities/profile_stats_entity.dart';
import '../../../wallet/domain/wallet_balances.dart';
import '../entities/jeton_package_entity.dart';
import '../entities/payment_config_entity.dart';
import '../entities/referral_info_entity.dart';

abstract class ProfileRepository {
  Future<UserEntity> getUser(String id);
  Future<void> follow(String id);
  Future<void> unfollow(String id);
  Future<UserEntity> updateMe({
    String? displayName,
    String? bio,
    String? avatarUrl,
    String? username,
    String? currentPassword,
    String? newPassword,
  });
  Future<ProfileStatsEntity> myStats();
  Future<List<GiftReceivedSummaryEntity>> giftsReceivedSummary();
  Future<List<BroadcastHistoryItemEntity>> broadcastHistory();
  Future<PagedResult<BroadcastHistoryItemEntity>> broadcastHistoryPage({
    int page,
  });
  Future<List<ProfileActivityItemEntity>> myActivity();
  Future<PagedResult<ProfileActivityItemEntity>> myActivityPage({int page});
  Future<void> markAllActivityRead();
  Future<List<UserEntity>> followers(String userId);
  Future<List<UserEntity>> following(String userId);
}

abstract class WalletRepository {
  Future<int> coinBalance();
  Future<WalletBalances> balances();
  Future<List<JetonPackageEntity>> jetonPackages();
  Future<PaymentConfigEntity> paymentConfig();
  Future<void> submitPaymentRequest(Map<String, dynamic> body);
  Future<List<CfcPaymentRequestEntity>> myPaymentRequests();
  Future<PagedResult<CfcPaymentRequestEntity>> myPaymentRequestsPage({
    int page,
  });
  Future<ReferralInfoEntity> referralInfo();
  Future<int> watchAdCredit();
}
