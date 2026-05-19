import '../entities/entities.dart';

abstract class AuthRepository {
  Future<AppUser> signIn({
    required String email,
    required String password,
  });

  Future<AppUser> register({
    required String email,
    required String password,
    required String displayName,
  });

  Future<void> resetPassword(String email);

  Future<void> signOut();

  Future<AppUser?> restoreSession();
}
