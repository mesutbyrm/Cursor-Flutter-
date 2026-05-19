import '../../domain/entities/entities.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_remote_datasource.dart';

class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl(this._remote);

  final AuthRemoteDatasource _remote;

  @override
  Future<AppUser> signIn({
    required String email,
    required String password,
  }) =>
      _remote.signIn(email: email, password: password);

  @override
  Future<AppUser> register({
    required String email,
    required String password,
    required String displayName,
  }) =>
      _remote.register(
        email: email,
        password: password,
        displayName: displayName,
      );

  @override
  Future<void> resetPassword(String email) => _remote.resetPassword(email);

  @override
  Future<void> signOut() => _remote.signOut();

  @override
  Future<AppUser?> restoreSession() => _remote.restoreSession();
}
