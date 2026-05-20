import '../../../auth/domain/entities/user_entity.dart';
import '../entities/jeton_package_entity.dart';
import '../entities/referral_info_entity.dart';

abstract class ProfileRepository {
  Future<UserEntity> getUser(String id);
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
