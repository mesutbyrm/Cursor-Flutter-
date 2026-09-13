import 'package:dio/dio.dart';

import '../network/api_endpoints.dart';
import '../network/dio_provider.dart';
import '../util/json_util.dart';

/// Abacus §2 / §10 — `GET /api/me/membership*` ve VIP tercihleri (ham JSON).
class MeEntitlementsRemoteDataSource {
  MeEntitlementsRemoteDataSource(this._dio);

  final Dio _dio;

  Future<Map<String, dynamic>> fetchMembership() async {
    final res = await _dio.safeGet<dynamic>(ApiEndpoints.meMembership);
    return asJsonMap(res.data);
  }

  Future<Map<String, dynamic>> fetchMembershipEvents() async {
    final res = await _dio.safeGet<dynamic>(ApiEndpoints.meMembershipEvents);
    return asJsonMap(res.data);
  }

  Future<Map<String, dynamic>> fetchMembershipHistory() async {
    final res = await _dio.safeGet<dynamic>(ApiEndpoints.meMembershipHistory);
    return asJsonMap(res.data);
  }

  Future<Map<String, dynamic>> fetchVipPreferences() async {
    final res = await _dio.safeGet<dynamic>(ApiEndpoints.meVipPreferences);
    return asJsonMap(res.data);
  }

  Future<Map<String, dynamic>> updateVipPreferences(
    Map<String, dynamic> body,
  ) async {
    final res = await _dio.safePut<dynamic>(
      ApiEndpoints.meVipPreferences,
      data: body,
    );
    return asJsonMap(res.data);
  }

  Future<Map<String, dynamic>> fetchVipIdentity() async {
    final res = await _dio.safeGet<dynamic>(ApiEndpoints.meVipIdentity);
    return asJsonMap(res.data);
  }

  Future<Map<String, dynamic>> updateVipIdentity(Map<String, dynamic> body) async {
    final res = await _dio.safePut<dynamic>(
      ApiEndpoints.meVipIdentity,
      data: body,
    );
    return asJsonMap(res.data);
  }

  Future<Map<String, dynamic>> fetchVipXp() async {
    final res = await _dio.safeGet<dynamic>(ApiEndpoints.meVipXp);
    return asJsonMap(res.data);
  }

  Future<Map<String, dynamic>> postVipXp(Map<String, dynamic> body) async {
    final res = await _dio.safePost<dynamic>(ApiEndpoints.meVipXp, data: body);
    return asJsonMap(res.data);
  }

  Future<Map<String, dynamic>> putMembershipHistory(
    Map<String, dynamic> body,
  ) async {
    final res = await _dio.safePut<dynamic>(
      ApiEndpoints.meMembershipHistory,
      data: body,
    );
    return asJsonMap(res.data);
  }

  Future<Map<String, dynamic>> fetchProfileVisitors({int? limit}) async {
    final res = await _dio.safeGet<dynamic>(
      ApiEndpoints.meProfileVisitorsCanonical,
      query: {if (limit != null) 'limit': limit.toString()},
    );
    return asJsonMap(res.data);
  }

  Future<Map<String, dynamic>> postProfileVisitors(
    Map<String, dynamic> body, {
    int? limit,
  }) async {
    final res = await _dio.safePost<dynamic>(
      ApiEndpoints.meProfileVisitorsCanonical,
      data: body,
      query: {if (limit != null) 'limit': limit.toString()},
    );
    return asJsonMap(res.data);
  }

  Future<Map<String, dynamic>> fetchAdminCapabilities() async {
    final res = await _dio.safeGet<dynamic>(ApiEndpoints.meAdminCapabilities);
    return asJsonMap(res.data);
  }
}
