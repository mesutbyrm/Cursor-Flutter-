import '../../../auth/domain/entities/user_entity.dart';

abstract class ProfileRepository {
  Future<UserEntity> getUser(String id);
  Future<void> follow(String id);
  Future<void> unfollow(String id);
}

abstract class WalletRepository {
  Future<int> coinBalance();
}
