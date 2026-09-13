import '../../features/auth/data/datasources/auth_remote_datasource.dart';

/// Abacus §1 kimlik uçları — tek HTTP katmanı [AuthRemoteDataSource].
class AbacusAuthRemoteDataSource {
  AbacusAuthRemoteDataSource(this._auth);

  final AuthRemoteDataSource _auth;

  Future<Map<String, dynamic>> sendEmailVerification([
    Map<String, dynamic>? body,
  ]) =>
      _auth.postEmailSendVerification(body);

  Future<Map<String, dynamic>> sendPhoneOtp(Map<String, dynamic> body) =>
      _auth.postPhoneSendOtp(body);

  /// `authentication.md` — gövde yalnız `{ phone }`.
  Future<Map<String, dynamic>> sendPhoneOtpForPhone(String phone) =>
      sendPhoneOtp({'phone': phone.trim()});

  Future<Map<String, dynamic>> verifyPhoneOtp(Map<String, dynamic> body) =>
      _auth.postPhoneVerifyOtp(body);

  Future<Map<String, dynamic>> verifyPhoneOtpForPhone({
    required String phone,
    required String code,
  }) =>
      verifyPhoneOtp({
        'phone': phone.trim(),
        'code': code.trim(),
      });

  Future<Map<String, dynamic>> fetchVerificationStatus() =>
      _auth.fetchVerificationRoute();

  Future<Map<String, dynamic>> submitVerification(Map<String, dynamic> body) =>
      _auth.postVerificationRoute(body);
}
