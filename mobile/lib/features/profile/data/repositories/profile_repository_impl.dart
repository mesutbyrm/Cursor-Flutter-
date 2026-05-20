import '../../../auth/domain/entities/user_entity.dart';
import '../../domain/entities/jeton_package_entity.dart';
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
}

class WalletRepositoryImpl implements WalletRepository {
  WalletRepositoryImpl(this._remote);

  final WalletRemoteDataSource _remote;

  @override
  Future<int> coinBalance() => _remote.balance();

  @override
  Future<List<JetonPackageEntity>> jetonPackages() => _remote.jetonPackages();

  @override
  Future<ReferralInfoEntity> referralInfo() => _remote.referralInfo();
}
