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
    final path =
        Env.useMobileAuth ? ApiEndpoints.authMobileLogin : ApiEndpoints.authLogin;
    final res = await _dio.safePost<Map<String, dynamic>>(
      path,
      data: {'email': email, 'password': password},
    );
    return _unwrapAuthBody(res.data);
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
