import 'package:dio/dio.dart';

import '../../../../core/config/env.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/network/dio_provider.dart';

class AuthRemoteDataSource {
  AuthRemoteDataSource(this._dio);

  final Dio _dio;

  Future<Map<String, dynamic>> login({
    required String identifier,
    required String password,
  }) async {
    final path =
        Env.useMobileAuth ? ApiEndpoints.authMobileLogin : ApiEndpoints.authLogin;
    final trimmed = identifier.trim();
    // Kılavuz §9.1 — `{email}` veya `{username}` + `password` (emailOrUsername yok).
    final body = trimmed.contains('@')
        ? {'email': trimmed, 'password': password}
        : Env.useMobileAuth
            ? {'username': trimmed, 'password': password}
            : {'email': trimmed, 'password': password};
    final res = await _dio.safePost<Map<String, dynamic>>(
      path,
      data: body,
    );
    return _unwrapAuthBody(res.data);
  }

  Future<void> sendEmailVerification({String? email}) async {
    await _dio.safePost<dynamic>(
      ApiEndpoints.authMobileSendVerification,
      data: {if (email != null && email.isNotEmpty) 'email': email},
    );
  }

  Future<void> verifyEmail({
    required String email,
    required String code,
  }) async {
    await _dio.safePost<dynamic>(
      ApiEndpoints.authMobileVerifyEmail,
      data: {'email': email, 'code': code},
    );
  }

  Future<List<Map<String, dynamic>>> fetchActiveSessions() async {
    final res = await _dio.safeGet<Map<String, dynamic>>(
      ApiEndpoints.authMobileSessions,
    );
    final root = res.data ?? {};
    final sessions = root['sessions'] ?? root['data']?['sessions'];
    if (sessions is List) {
      return sessions
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList(growable: false);
    }
    return const [];
  }

  Future<void> revokeSession(String sessionId) async {
    await _dio.safeDelete<dynamic>(
      ApiEndpoints.authMobileSessionRevoke(sessionId),
    );
  }

  Future<Map<String, dynamic>> register({
    required String email,
    required String password,
    required String displayName,
    required String username,
    String? phone,
    String? birthDate,
    String? birthTime,
    String language = 'tr',
    String? referralCode,
  }) async {
    if (Env.useMobileAuth) {
      if (birthDate == null ||
          birthDate.isEmpty ||
          birthTime == null ||
          birthTime.isEmpty) {
        throw const ApiException(
          'Doğum tarihi ve doğum saati zorunludur',
        );
      }
      final res = await _dio.safePost<Map<String, dynamic>>(
        ApiEndpoints.authMobileRegister,
        data: {
          'email': email,
          'password': password,
          'name': displayName,
          'username': username,
          'birthDate': birthDate,
          'birthTime': birthTime,
          'preferredLanguage': language,
          if (referralCode != null && referralCode.isNotEmpty)
            'referralCode': referralCode,
        },
      );
      return _unwrapAuthBody(res.data);
    }

    final res = await _dio.safePost<Map<String, dynamic>>(
      ApiEndpoints.authRegister,
      data: {
        'email': email,
        'password': password,
        'displayName': displayName,
        'username': username,
        if (phone != null && phone.isNotEmpty) 'phone': phone,
        if (birthDate != null && birthDate.isNotEmpty) 'birthDate': birthDate,
        if (birthTime != null && birthTime.isNotEmpty) 'birthTime': birthTime,
        'language': language,
      },
    );
    return _unwrapAuthBody(res.data);
  }

  Future<void> requestPasswordReset(String email) async {
    await _dio.safePost<dynamic>(
      ApiEndpoints.authForgotPassword,
      data: {'email': email.trim().toLowerCase()},
    );
  }

  Future<void> resetPassword({
    required String token,
    required String password,
  }) async {
    await _dio.safePost<dynamic>(
      ApiEndpoints.authResetPassword,
      data: {
        'token': token.trim(),
        'password': password,
      },
    );
  }

  Future<Map<String, dynamic>> me() async {
    final path = Env.useMobileAuth ? ApiEndpoints.me : ApiEndpoints.authMe;
    final res = await _dio.safeGet<Map<String, dynamic>>(path);
    return _unwrapAuthBody(res.data);
  }

  Map<String, dynamic> _unwrapAuthBody(Map<String, dynamic>? body) {
    if (body == null) return {};
    if (body['data'] is Map) {
      return Map<String, dynamic>.from(body['data'] as Map);
    }
    return body;
  }
}
