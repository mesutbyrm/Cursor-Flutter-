import 'package:dio/dio.dart';

import '../../../../core/network/api_endpoints.dart';
import '../../../../core/network/dio_provider.dart';

class AuthRemoteDataSource {
  AuthRemoteDataSource(this._dio);

  final Dio _dio;

  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    final res = await _dio.safePost<Map<String, dynamic>>(
      ApiEndpoints.authLogin,
      data: {'email': email, 'password': password},
    );
    return res.data ?? {};
  }

  Future<Map<String, dynamic>> register({
    required String email,
    required String password,
    String? displayName,
  }) async {
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
    final res = await _dio.safeGet<Map<String, dynamic>>(ApiEndpoints.authMe);
    return res.data ?? {};
  }
}
