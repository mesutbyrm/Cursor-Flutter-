import '../../core/result/pf_result.dart';
import '../entities/pf_user.dart';

abstract interface class PfAuthRepository {
  Stream<PfUser?> watchCurrentUser();
  Future<PfResult<PfUser>> signInWithEmail(String email, String password);
  Future<PfResult<PfUser>> registerWithEmail(
    String email,
    String password,
    String displayName,
  );
  Future<PfResult<PfUser>> signInWithGoogle();
  Future<PfResult<PfUser>> signInWithApple();
  Future<PfResult<void>> signOut();
  Future<PfResult<PfUser>> updateProfile({
    String? displayName,
    String? photoUrl,
    DateTime? birthDate,
    String? zodiacSign,
  });
}
