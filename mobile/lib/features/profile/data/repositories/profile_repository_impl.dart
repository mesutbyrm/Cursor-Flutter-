import '../../../auth/domain/entities/user_entity.dart';
import '../../domain/entities/broadcast_history_item.dart';
import '../../domain/entities/jeton_package_entity.dart';
import '../../domain/entities/referral_info_entity.dart';
import '../../domain/entities/user_activity_item.dart';
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
      } catch (_) {
        // Yedek: doğrudan id ile dene
      }
    }
    return _remote.user(id);
  }

  @override
  Future<UserEntity> lookupByUsername(String username) =>
      _canlifal.lookupByUsername(username);

  @override
  Future<List<BroadcastHistoryItem>> broadcastHistory({
    int page = 1,
    int limit = 20,
    String status = 'ended',
  }) =>
      _canlifal.broadcastHistory(page: page, limit: limit, status: status);

  @override
  Future<List<UserActivityItem>> fetchActivity({bool unreadOnly = false}) =>
      _canlifal.fetchActivity(unreadOnly: unreadOnly);

  @override
  Future<void> markAllActivityRead() => _canlifal.markAllActivityRead();

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
