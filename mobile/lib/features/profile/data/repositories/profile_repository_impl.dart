import '../../../../core/performance/network_perf.dart';
import '../../../auth/domain/entities/user_entity.dart';
import '../../../wallet/domain/cfc_payment_request_entity.dart';
import '../../../wallet/domain/wallet_balances.dart';
import '../../domain/entities/jeton_package_entity.dart';
import '../../../../core/pagination/paged_result.dart';
import '../../domain/entities/profile_extended_entity.dart';
import '../../domain/entities/profile_stats_entity.dart';
import '../../domain/entities/payment_config_entity.dart';
import '../../domain/entities/referral_info_entity.dart';
import '../../domain/repositories/profile_repository.dart';
import '../datasources/canlifal_user_api_datasource.dart';
import '../datasources/profile_remote_datasource.dart';

class ProfileRepositoryImpl implements ProfileRepository {
  ProfileRepositoryImpl(this._remote, this._canlifal);

  final ProfileRemoteDataSource _remote;
  final CanlifalUserApiDataSource _canlifal;

  @override
  Future<UserEntity> getUser(String id) async {
    if (ProfileRemoteDataSource.looksLikeUsernameKey(id)) {
      try {
        return await _canlifal.lookupByUsername(id);
      } catch (_) {}
    }
    return _remote.user(id);
  }

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
    String? birthDate,
    String? birthTime,
    String? favoriteTeam,
  }) =>
      _remote.updateMe(
        displayName: displayName,
        bio: bio,
        avatarUrl: avatarUrl,
        username: username,
        currentPassword: currentPassword,
        newPassword: newPassword,
        birthDate: birthDate,
        birthTime: birthTime,
        favoriteTeam: favoriteTeam,
      );

  @override
  Future<ProfileStatsEntity> myStats() async {
    final results = await NetworkPerf.parallel<Object?>([
      () async {
        try {
          return await _remote.myStats();
        } catch (_) {
          return const ProfileStatsEntity();
        }
      }(),
      () async {
        try {
          return await _remote.mySiteProfile();
        } catch (_) {
          return null;
        }
      }(),
      () async {
        try {
          return await _remote.broadcastHistory();
        } catch (_) {
          return const <BroadcastHistoryItemEntity>[];
        }
      }(),
      () async {
        try {
          return await _remote.profileVisitorCount();
        } catch (_) {
          return 0;
        }
      }(),
    ]);
    var stats = results[0] as ProfileStatsEntity;
    final profile = results[1] as UserEntity?;
    final broadcasts = results[2] as List<BroadcastHistoryItemEntity>;
    final visitorCount = results[3] as int;

    if (profile != null) {
      stats = ProfileStatsEntity(
        liveStreams: stats.liveStreams,
        likes: stats.likes,
        followers: stats.followers > 0 ? stats.followers : profile.followersCount,
        following: stats.following > 0 ? stats.following : profile.followingCount,
        giftsReceivedCount: stats.giftsReceivedCount,
        giftsReceivedCoins: stats.giftsReceivedCoins,
        earningsJeton: stats.earningsJeton,
        approvedTopUpTotal: stats.approvedTopUpTotal,
        profileViews: stats.profileViews > 0 ? stats.profileViews : visitorCount,
      );
    } else if (stats.profileViews == 0 && visitorCount > 0) {
      stats = ProfileStatsEntity(
        liveStreams: stats.liveStreams,
        likes: stats.likes,
        followers: stats.followers,
        following: stats.following,
        giftsReceivedCount: stats.giftsReceivedCount,
        giftsReceivedCoins: stats.giftsReceivedCoins,
        earningsJeton: stats.earningsJeton,
        approvedTopUpTotal: stats.approvedTopUpTotal,
        profileViews: visitorCount,
      );
    }

    if (stats.liveStreams == 0 && broadcasts.isNotEmpty) {
      stats = ProfileStatsEntity(
        liveStreams: broadcasts.length,
        likes: stats.likes,
        followers: stats.followers,
        following: stats.following,
        giftsReceivedCount: stats.giftsReceivedCount,
        giftsReceivedCoins: stats.giftsReceivedCoins,
        earningsJeton: stats.earningsJeton,
        approvedTopUpTotal: stats.approvedTopUpTotal,
        profileViews: stats.profileViews,
      );
    }

    return stats;
  }

  @override
  Future<ProfileExtendedEntity> extendedProfile() async {
    final ext = await _remote.extendedProfile();
    if (ext.dailyStreak > 0) return ext;
    final streak = await _remote.fetchDailyStreak();
    if (streak <= 0) return ext;
    return ProfileExtendedEntity(
      city: ext.city,
      zodiacSign: ext.zodiacSign,
      birthDate: ext.birthDate,
      birthTime: ext.birthTime,
      joinedAt: ext.joinedAt,
      phone: ext.phone,
      isOnline: ext.isOnline,
      dailyStreak: streak,
      vipLevel: ext.vipLevel,
      coverImage: ext.coverImage,
      raw: ext.raw,
    );
  }

  @override
  Future<ProfileUserStatisticsEntity> userStatistics() =>
      _remote.userStatistics();

  @override
  Future<void> deleteAvatar() => _remote.deleteAvatar();

  @override
  Future<List<GiftReceivedSummaryEntity>> giftsReceivedSummary() =>
      _remote.giftsReceivedSummary();

  @override
  Future<List<BroadcastHistoryItemEntity>> broadcastHistory() async {
    final page = await broadcastHistoryPage(page: 1);
    return page.items;
  }

  @override
  Future<PagedResult<BroadcastHistoryItemEntity>> broadcastHistoryPage({
    int page = 1,
  }) async {
    try {
      final site = await _canlifal.broadcastHistory(page: page);
      if (site.items.isNotEmpty) return site;
    } catch (_) {}
    final items = await _remote.broadcastHistory();
    return PagedResult(items: items, hasMore: false);
  }

  @override
  Future<List<ProfileActivityItemEntity>> myActivity() async {
    final page = await myActivityPage(page: 1);
    return page.items;
  }

  @override
  Future<PagedResult<ProfileActivityItemEntity>> myActivityPage({
    int page = 1,
  }) async {
    try {
      final site = await _canlifal.fetchActivity(page: page);
      if (site.items.isNotEmpty) return site;
    } catch (_) {}
    final items = await _remote.myActivity();
    return PagedResult(items: items, hasMore: false);
  }

  @override
  Future<void> markAllActivityRead() => _canlifal.markAllActivityRead();

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
  Future<WalletBalances> balances({bool forceRefresh = false}) =>
      _remote.balances(forceRefresh: forceRefresh);

  @override
  Future<List<JetonPackageEntity>> jetonPackages() => _remote.jetonPackages();

  @override
  Future<PaymentConfigEntity> paymentConfig() => _remote.paymentConfig();

  @override
  Future<void> submitPaymentRequest(Map<String, dynamic> body) =>
      _remote.submitPaymentRequest(body);

  @override
  Future<void> cancelPaymentRequest(String requestId) =>
      _remote.cancelPaymentRequest(requestId);

  @override
  Future<List<CfcPaymentRequestEntity>> myPaymentRequests() async {
    final page = await myPaymentRequestsPage(page: 1);
    return page.items;
  }

  @override
  Future<PagedResult<CfcPaymentRequestEntity>> myPaymentRequestsPage({
    int page = 1,
  }) =>
      _remote.myPaymentRequestsPage(page: page);

  @override
  Future<ReferralInfoEntity> referralInfo() => _remote.referralInfo();

  @override
  Future<int> watchAdCredit() => _remote.watchAdCredit();
}
