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
    if (Env.useNextAuth) {
      return _loginNextAuth(email: email, password: password);
    }
    final res = await _dio.safePost<Map<String, dynamic>>(
      ApiEndpoints.authLogin,
      data: {'email': email, 'password': password},
    );
    return res.data ?? {};
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
      if (url.contains('/api/auth/signin')) {
        throw const ApiException('E-posta veya şifre hatalı', statusCode: 401);
      }
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
    String? displayName,
  }) async {
    if (Env.useNextAuth) {
      throw const ApiException(
        'Kayıt şu an yalnızca canlifal.com web sitesinden yapılabilir.',
      );
    }
    final res = await _dio.safePost<Map<String, dynamic>>(
      ApiEndpoints.authRegister,
      data: {
        'email': email,
        'password': password,
        if (displayName != null && displayName.isNotEmpty)
          'displayName': displayName,
      },
    );
    return res.data ?? {};
  }

  Future<Map<String, dynamic>> me() async {
    if (Env.useNextAuth) {
      return session();
    }
    final res = await _dio.safeGet<Map<String, dynamic>>(ApiEndpoints.authMe);
    return res.data ?? {};
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
}
