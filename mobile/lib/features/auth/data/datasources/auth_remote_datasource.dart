import 'package:dio/dio.dart';

import '../../../../core/network/api_endpoints.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/network/dio_provider.dart';
import '../../../../core/util/json_util.dart';

class AuthRemoteDataSource {
  AuthRemoteDataSource(this._dio);

  final Dio _dio;

  Future<Map<String, dynamic>> login({
    required String identifier,
    required String password,
  }) async {
    final trimmed = identifier.trim();
    // Kılavuz §9.1 — `{email}` veya `{username}` + `password`.
    final body = trimmed.contains('@')
        ? {
            'email': trimmed,
            'emailOrUsername': trimmed,
            'password': password,
          }
        : {
            'username': trimmed,
            'emailOrUsername': trimmed,
            'password': password,
          };
    final res = await _dio.safePost<Map<String, dynamic>>(
      ApiEndpoints.authMobileLogin,
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
        query: {'deviceId': deviceId},
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
      final root = res.data;
      final rows = _parseSessionRows(root);
      if (rows.isNotEmpty) return rows;
      if (_authSessionsResponseRecognized(root)) return rows;
      return null;
    } on DioException catch (e) {
      final status = e.response?.statusCode;
      if (status == 404 || status == 405) return null;
      rethrow;
    }
  }

  bool _authSessionsResponseRecognized(Map<String, dynamic>? root) {
    if (root == null || root.isEmpty) return false;
    if (root.containsKey('sessions') ||
        root.containsKey('devices') ||
        root['data'] is Map &&
            ((root['data'] as Map).containsKey('sessions') ||
                (root['data'] as Map).containsKey('devices'))) {
      return true;
    }
    return root.containsKey('lastGlobalLogoutAt');
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
        if (phone != null && phone.isNotEmpty) 'phone': phone,
        if (referralCode != null && referralCode.isNotEmpty)
          'referralCode': referralCode,
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
    final res = await _dio.safeGet<Map<String, dynamic>>(ApiEndpoints.me);
    return _unwrapAuthBody(res.data);
  }

  /// Abacus `POST /api/auth/email/send-verification` (OpenAPI; ham gövde).
  Future<Map<String, dynamic>> postEmailSendVerification([
    Map<String, dynamic>? body,
  ]) async {
    final res = await _dio.safePost<dynamic>(
      ApiEndpoints.authEmailSendVerification,
      data: body ?? const <String, dynamic>{},
    );
    return asJsonMap(res.data);
  }

  /// `authentication.md` BÖLÜM 17 — gövde `{ phone }`. Ham `Map` yalnızca bu anahtarlar için.
  Future<Map<String, dynamic>> postPhoneSendOtp(Map<String, dynamic> body) async {
    final res = await _dio.safePost<dynamic>(
      ApiEndpoints.authPhoneSendOtp,
      data: body,
    );
    return asJsonMap(res.data);
  }

  /// `authentication.md` BÖLÜM 17 — gövde `{ phone, code }`.
  Future<Map<String, dynamic>> postPhoneVerifyOtp(Map<String, dynamic> body) async {
    final res = await _dio.safePost<dynamic>(
      ApiEndpoints.authPhoneVerifyOtp,
      data: body,
    );
    return asJsonMap(res.data);
  }

  Future<Map<String, dynamic>> fetchVerificationRoute() async {
    final res = await _dio.safeGet<dynamic>(ApiEndpoints.authVerification);
    return asJsonMap(res.data);
  }

  Future<Map<String, dynamic>> postVerificationRoute(
    Map<String, dynamic> body,
  ) async {
    final res = await _dio.safePost<dynamic>(
      ApiEndpoints.authVerification,
      data: body,
    );
    return asJsonMap(res.data);
  }

  Map<String, dynamic> _unwrapAuthBody(Map<String, dynamic>? body) {
    if (body == null) return {};
    if (body['data'] is Map) {
      return Map<String, dynamic>.from(body['data'] as Map);
    }
    return body;
  }
}
