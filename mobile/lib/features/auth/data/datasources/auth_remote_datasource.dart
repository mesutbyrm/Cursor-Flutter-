import 'package:dio/dio.dart';

import '../../../../core/config/env.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/network/dio_provider.dart';

class AuthRemoteDataSource {
  AuthRemoteDataSource(this._dio);

  final Dio _dio;

  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    // canlifal.com: /api/auth/login NextAuth tarafından 400 döner — doğrudan credentials.
    if (Env.useNextAuth) {
      return _loginNextAuth(email: email, password: password);
    }
    try {
      return await _loginJwt(email: email, password: password);
    } on ApiException catch (e) {
      if (_shouldFallbackToNextAuth(e)) {
        return _loginNextAuth(email: email, password: password);
      }
      rethrow;
    }
  }

  /// SQL JWT uçları yok veya NextAuth ile çakışıyor.
  static bool _shouldFallbackToNextAuth(ApiException e) {
    final code = e.statusCode;
    if (code != 404 && code != 400 && code != 405) return false;
    final m = e.message.toLowerCase();
    return m.contains('nextauth') ||
        m.contains('not supported') ||
        code == 404;
  }

  Future<Map<String, dynamic>> _loginJwt({
    required String email,
    required String password,
  }) async {
    final res = await _dio.safePost<Map<String, dynamic>>(
      ApiEndpoints.authLogin,
      data: {'email': email, 'password': password},
    );
    return _unwrap(res.data);
  }

  Future<Map<String, dynamic>> _loginNextAuth({
    required String email,
    required String password,
  }) async {
    final csrf = await _fetchCsrf();
    final res = await _dio.post<dynamic>(
      ApiEndpoints.authCredentials,
      data: {
        'csrfToken': csrf,
        'email': email,
        'password': password,
        'callbackUrl': Env.siteOrigin,
        'json': 'true',
      },
      options: Options(
        contentType: Headers.formUrlEncodedContentType,
        followRedirects: false,
        validateStatus: (s) => s != null && s < 500,
      ),
    );
    final code = res.statusCode ?? 0;
    if (code == 401) {
      throw const ApiException('E-posta veya şifre hatalı', statusCode: 401);
    }
    final data = res.data;
    if (data is Map) {
      final url = data['url']?.toString() ?? '';
      if (url.contains('/api/auth/signin') ||
          url.contains('csrf=true') ||
          url.contains('error=')) {
        throw const ApiException('E-posta veya şifre hatalı', statusCode: 401);
      }
    }
    if (code >= 400) {
      throw ApiException(
        'Giriş başarısız (${code})',
        statusCode: code,
      );
    }
    return {'ok': true};
  }

  Future<String> _fetchCsrf() async {
    final res = await _dio.safeGet<Map<String, dynamic>>(ApiEndpoints.authCsrf);
    final t = res.data?['csrfToken'];
    if (t is! String || t.isEmpty) {
      throw const ApiException('Güvenlik anahtarı (csrf) alınamadı');
    }
    return t;
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
  }) async {
    if (Env.useNextAuth) {
      throw const ApiException(
        'E-posta ile kayıt bu sunucuda henüz desteklenmiyor. '
        'Google ile kayıt olun veya canlifal.com üzerinden hesap oluşturun.',
      );
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
    return _unwrap(res.data);
  }

  Future<Map<String, dynamic>> me() async {
    final res = await _dio.safeGet<Map<String, dynamic>>(ApiEndpoints.authMe);
    return _unwrap(res.data);
  }

  Future<Map<String, dynamic>> session() async {
    final res = await _dio.safeGet<dynamic>(ApiEndpoints.authSession);
    final d = res.data;
    if (d is Map<String, dynamic>) return d;
    if (d is Map) return Map<String, dynamic>.from(d);
    return {};
  }

  Future<void> signOutNextAuth() async {
    final csrf = await _fetchCsrf();
    await _dio.safePost<dynamic>(
      ApiEndpoints.authSignOut,
      data: {'csrfToken': csrf, 'json': 'true'},
      options: Options(contentType: Headers.formUrlEncodedContentType),
    );
  }

  Map<String, dynamic> _unwrap(Map<String, dynamic>? body) {
    if (body == null) return {};
    final data = body['data'];
    if (data is Map<String, dynamic>) return data;
    if (data is Map) return Map<String, dynamic>.from(data);
    return body;
  }
}
