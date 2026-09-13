import 'package:dio/dio.dart';

import '../../../../core/network/api_endpoints.dart';
import '../../../../core/network/dio_provider.dart';
import '../../../../core/util/json_util.dart';

/// Abacus zip §2 — sosyal ayarlar, hesap ve astroloji paneli.
class UserAbacusRemoteDataSource {
  UserAbacusRemoteDataSource(this._dio);

  final Dio _dio;

  Future<Map<String, dynamic>> fetchSocialSettings() async {
    final res = await _dio.safeGet<dynamic>(ApiEndpoints.userSocialSettings);
    return asJsonMap(res.data);
  }

  Future<Map<String, dynamic>> updateSocialSettings(
    Map<String, dynamic> body,
  ) async {
    final res = await _dio.safePut<dynamic>(
      ApiEndpoints.userSocialSettings,
      data: body,
    );
    return asJsonMap(res.data);
  }

  Future<Map<String, dynamic>> fetchUserAchievements(String userId) async {
    final res = await _dio.safeGet<dynamic>(
      ApiEndpoints.userAchievementsFor(userId),
    );
    return asJsonMap(res.data);
  }

  Future<Map<String, dynamic>> postUserAccount(Map<String, dynamic> body) async {
    final res = await _dio.safePost<dynamic>(
      ApiEndpoints.userAccount,
      data: body,
    );
    return asJsonMap(res.data);
  }

  Future<Map<String, dynamic>> deleteUserAccount() async {
    final res = await _dio.safeDelete<dynamic>(ApiEndpoints.userAccount);
    return asJsonMap(res.data);
  }

  Future<Map<String, dynamic>> fetchAstrologyPanel() async {
    final res = await _dio.safeGet<dynamic>(ApiEndpoints.astrologyPanel);
    return asJsonMap(res.data);
  }
}
