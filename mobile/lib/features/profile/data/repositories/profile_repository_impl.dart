import '../../../auth/domain/entities/user_entity.dart';
import '../../../wallet/domain/cfc_payment_request_entity.dart';
import '../../../wallet/domain/wallet_balances.dart';
import '../../domain/entities/jeton_package_entity.dart';
import '../../domain/entities/profile_stats_entity.dart';
import '../../domain/entities/payment_config_entity.dart';
import '../../domain/entities/referral_info_entity.dart';
import '../../domain/repositories/profile_repository.dart';
import '../datasources/profile_remote_datasource.dart';

class ProfileRepositoryImpl implements ProfileRepository {
  ProfileRepositoryImpl(this._remote);

  final ProfileRemoteDataSource _remote;

  @override
  Future<UserEntity> getUser(String id) => _remote.user(id);

  @override
  Future<void> follow(String id) => _remote.follow(id);

  @override
  Future<void> unfollow(String id) => _remote.unfollow(id);

  @override
  Future<UserEntity> updateMe({
    String? displayName,
    String? bio,
    String? avatarUrl,
    String? username,
    String? currentPassword,
    String? newPassword,
  }) =>
      _remote.updateMe(
        displayName: displayName,
        bio: bio,
        avatarUrl: avatarUrl,
        username: username,
        currentPassword: currentPassword,
        newPassword: newPassword,
      );

  @override
  Future<ProfileStatsEntity> myStats() => _remote.myStats();

  @override
  Future<List<GiftReceivedSummaryEntity>> giftsReceivedSummary() =>
      _remote.giftsReceivedSummary();

  @override
  Future<List<BroadcastHistoryItemEntity>> broadcastHistory() =>
      _remote.broadcastHistory();

  @override
  Future<List<ProfileActivityItemEntity>> myActivity() => _remote.myActivity();

  @override
  Future<List<UserEntity>> followers(String userId) =>
      _remote.followers(userId);

  @override
  Future<List<UserEntity>> following(String userId) =>
      _remote.following(userId);
}

class WalletRepositoryImpl implements WalletRepository {
  WalletRepositoryImpl(this._remote);

  final WalletRemoteDataSource _remote;

  @override
  Future<int> coinBalance() => _remote.balance();

  @override
  Future<WalletBalances> balances() => _remote.balances();

  @override
  Future<List<JetonPackageEntity>> jetonPackages() => _remote.jetonPackages();

  @override
  Future<PaymentConfigEntity> paymentConfig() => _remote.paymentConfig();

  @override
  Future<void> submitPaymentRequest(Map<String, dynamic> body) =>
      _remote.submitPaymentRequest(body);

  @override
  Future<List<CfcPaymentRequestEntity>> myPaymentRequests() =>
      _remote.myPaymentRequests();

  @override
  Future<ReferralInfoEntity> referralInfo() => _remote.referralInfo();
}
