import 'package:dio/dio.dart';

import '../network/api_endpoints.dart';
import '../network/dio_provider.dart';
import '../util/json_util.dart';

/// Abacus zip §1 — e-posta / telefon OTP ve belge doğrulama uçları.
class AbacusAuthRemoteDataSource {
  AbacusAuthRemoteDataSource(this._dio);

  final Dio _dio;

  Future<Map<String, dynamic>> sendEmailVerification([
    Map<String, dynamic>? body,
  ]) async {
    final res = await _dio.safePost<dynamic>(
      ApiEndpoints.authEmailSendVerification,
      data: body ?? const <String, dynamic>{},
    );
    return asJsonMap(res.data);
  }

  Future<Map<String, dynamic>> sendPhoneOtp(Map<String, dynamic> body) async {
    final res = await _dio.safePost<dynamic>(
      ApiEndpoints.authPhoneSendOtp,
      data: body,
    );
    return asJsonMap(res.data);
  }

  Future<Map<String, dynamic>> verifyPhoneOtp(Map<String, dynamic> body) async {
    final res = await _dio.safePost<dynamic>(
      ApiEndpoints.authPhoneVerifyOtp,
      data: body,
    );
    return asJsonMap(res.data);
  }

  Future<Map<String, dynamic>> fetchVerificationStatus() async {
    final res = await _dio.safeGet<dynamic>(ApiEndpoints.authVerification);
    return asJsonMap(res.data);
  }

  Future<Map<String, dynamic>> submitVerification(
    Map<String, dynamic> body,
  ) async {
    final res = await _dio.safePost<dynamic>(
      ApiEndpoints.authVerification,
      data: body,
    );
    return asJsonMap(res.data);
  }
}
