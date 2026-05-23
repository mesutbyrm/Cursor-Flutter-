import '../entities/user_entity.dart';

abstract class AuthRepository {
  Future<UserEntity> login({required String email, required String password});
  Future<UserEntity> register({
    required String email,
    required String password,
    required String displayName,
    required String username,
    String? phone,
    String? birthDate,
    String? birthTime,
    String language,
  });
  Future<UserEntity> loginWithGoogle();
  Future<UserEntity> loginWithTikTok();
  Future<UserEntity?> currentUser();
  Future<void> logout();
}
