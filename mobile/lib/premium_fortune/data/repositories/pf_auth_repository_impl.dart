import '../../core/errors/pf_failure.dart';
import '../../core/result/pf_result.dart';
import '../../domain/entities/pf_user.dart';
import '../../domain/repositories/pf_auth_repository.dart';
import '../datasources/pf_firebase_auth_datasource.dart';

class PfAuthRepositoryImpl implements PfAuthRepository {
  PfAuthRepositoryImpl(this._datasource);

  final PfFirebaseAuthDatasource _datasource;

  @override
  Stream<PfUser?> watchCurrentUser() => _datasource.watchCurrentUser();

  @override
  Future<PfResult<PfUser>> signInWithEmail(String email, String password) =>
      _guard(() => _datasource.signInWithEmail(email, password));

  @override
  Future<PfResult<PfUser>> registerWithEmail(
    String email,
    String password,
    String displayName,
  ) =>
      _guard(() => _datasource.registerWithEmail(email, password, displayName));

  @override
  Future<PfResult<PfUser>> signInWithGoogle() =>
      _guard(() => _datasource.signInWithGoogle());

  @override
  Future<PfResult<PfUser>> signInWithApple() =>
      _guard(() => _datasource.signInWithApple());

  @override
  Future<PfResult<void>> signOut() =>
      _guard(() => _datasource.signOut());

  @override
  Future<PfResult<PfUser>> updateProfile({
    String? displayName,
    String? photoUrl,
    DateTime? birthDate,
    String? zodiacSign,
  }) =>
      _guard(
        () => _datasource.updateProfile(
          displayName: displayName,
          photoUrl: photoUrl,
          birthDate: birthDate,
          zodiacSign: zodiacSign,
        ),
      );

  Future<PfResult<T>> _guard<T>(Future<T> Function() action) async {
    try {
      return PfSuccess(await action());
    } on PfFailure catch (e) {
      return PfError(e);
    } catch (e) {
      return PfError(PfAuthFailure(e.toString()));
    }
  }
}
