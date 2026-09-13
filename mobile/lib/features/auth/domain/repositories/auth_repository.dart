import '../entities/active_session_entity.dart';
import '../entities/user_entity.dart';

abstract class AuthRepository {
  Future<UserEntity> login({required String identifier, required String password});
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
  Future<UserEntity> loginWithApple({String? referralCode});
  Future<UserEntity> loginWithTikTok();
  Future<UserEntity?> currentUser();
  Future<void> requestPasswordReset(String email);
  Future<void> sendEmailVerification({String? email});
  Future<void> verifyEmail({required String email, required String code});

  /// `POST /api/auth/phone/send-otp` — gövde `{ phone }` (authentication.md BÖLÜM 17).
  Future<Map<String, dynamic>> sendPhoneVerificationOtp(String phone);

  /// `POST /api/auth/phone/verify-otp` — gövde `{ phone, code }`.
  Future<Map<String, dynamic>> verifyPhoneVerificationOtp({
    required String phone,
    required String code,
  });
  Future<List<ActiveSessionEntity>> fetchActiveSessions();
  Future<void> revokeSession(String sessionId);
  Future<void> logoutAllDevices({bool removeDevices = false});
  Future<void> resetPassword({
    required String token,
    required String password,
  });
  Future<void> logout();
}
