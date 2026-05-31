import '../../../auth/domain/entities/user_entity.dart';
import '../entities/broadcast_history_item.dart';
import '../entities/jeton_package_entity.dart';
import '../entities/referral_info_entity.dart';
import '../entities/user_activity_item.dart';

abstract class ProfileRepository {
  Future<UserEntity> getUser(String id);

  /// `GET /api/users/lookup/{username}`
  Future<UserEntity> lookupByUsername(String username);

  /// `GET /api/user/broadcast-history`
  Future<List<BroadcastHistoryItem>> broadcastHistory({
    int page,
    int limit,
    String status,
  });

  /// `GET /api/user/activity`
  Future<List<UserActivityItem>> fetchActivity({bool unreadOnly});

  /// `PATCH /api/user/activity` — markAllRead
  Future<void> markAllActivityRead();

  Future<void> follow(String id);
  Future<void> unfollow(String id);
}

abstract class WalletRepository {
  Future<int> coinBalance();

  /// Site `/api/jeton` — paket listesi (şekil değişirse parser genişletilir).
  Future<List<JetonPackageEntity>> jetonPackages();

  /// Site `/api/referral` — paylaşılacak bağlantı / kod.
  Future<ReferralInfoEntity> referralInfo();
}
