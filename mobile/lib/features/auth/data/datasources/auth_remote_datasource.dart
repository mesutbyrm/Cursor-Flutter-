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
    final fromAbacus = await _tryFetchAuthSessions();
    if (fromAbacus != null) return fromAbacus;

    final res = await _dio.safeGet<Map<String, dynamic>>(
      ApiEndpoints.authMobileSessions,
    );
    return _parseSessionRows(res.data);
  }

  Future<void> revokeSession(String sessionId) async {
    final deviceId = sessionId.trim();
    if (deviceId.isEmpty) return;
    try {
      await _dio.safeDelete<dynamic>(
        ApiEndpoints.authSessions,
        queryParameters: {'deviceId': deviceId},
      );
      return;
    } on DioException catch (e) {
      final status = e.response?.statusCode;
      if (status != null && status != 404 && status != 405) {
        rethrow;
      }
    }
    await _dio.safeDelete<dynamic>(
      ApiEndpoints.authMobileSessionRevoke(deviceId),
    );
  }

  /// `POST /api/auth/logout-all` — `removeDevices` isteğe bağlı (`authentication.md`).
  Future<void> logoutAllDevices({bool removeDevices = false}) async {
    await _dio.safePost<dynamic>(
      ApiEndpoints.authLogoutAll,
      data: {if (removeDevices) 'removeDevices': true},
    );
  }

  Future<List<Map<String, dynamic>>?> _tryFetchAuthSessions() async {
    try {
      final res = await _dio.safeGet<Map<String, dynamic>>(
        ApiEndpoints.authSessions,
      );
      final rows = _parseSessionRows(res.data);
      if (rows.isNotEmpty) return rows;
      // Boş liste geçerli yanıt olabilir; yine Abacus uçunu kullan.
      return rows;
    } on DioException catch (e) {
      final status = e.response?.statusCode;
      if (status == 404 || status == 405) return null;
      rethrow;
    }
  }

  List<Map<String, dynamic>> _parseSessionRows(Map<String, dynamic>? root) {
    if (root == null) return const [];
    final sessions = root['sessions'] ??
        root['devices'] ??
        root['data']?['sessions'] ??
        root['data']?['devices'];
    if (sessions is List) {
      return sessions
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList(growable: false);
    }
    return const [];
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
