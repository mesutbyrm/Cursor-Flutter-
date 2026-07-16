import 'package:dio/dio.dart';

import '../core/api_response.dart';
import '../core/network/api_endpoints.dart';
import '../core/network/dio_provider.dart';
import '../core/util/json_util.dart';
import 'service_utils.dart';

/// Falcı API — kılavuz §9.6 `FortuneTellerRepository`.
class TellerService {
  TellerService({required Dio Function() resolveAuthedDio})
      : _resolveAuthedDio = resolveAuthedDio;

  final Dio Function() _resolveAuthedDio;
  Dio get _dio => _resolveAuthedDio();

  /// `GET /api/fortune-tellers`
  Future<ApiResponse<List<Map<String, dynamic>>>> getTellers({
    int page = 1,
    int limit = 20,
    bool? online,
  }) async {
    final res = await _dio.safeGet<dynamic>(
      ApiEndpoints.fortuneTellers,
      query: {
        ...apiPageQuery(page: page, limit: limit),
        if (online == true) 'online': 'true',
      },
    );
    return parseResponse<List<Map<String, dynamic>>>(
      res.data,
      fromData: (data) => ServiceUtils.extractList(
        data,
        keys: const ['tellers', 'items', 'data'],
      ),
    );
  }

  /// `GET /api/fortune-tellers/{id}`
  Future<Map<String, dynamic>> getTeller(String id) async {
    final res = await _dio.safeGet<dynamic>(ApiEndpoints.fortuneTeller(id));
    final map = ServiceUtils.unwrapMap(res.data) ?? asJsonMap(res.data);
    final teller = map['teller'] ?? map;
    return teller is Map ? Map<String, dynamic>.from(teller) : map;
  }

  /// `GET /api/fortune-tellers/{id}/reviews`
  Future<List<Map<String, dynamic>>> getReviews(
    String id, {
    int page = 1,
    int limit = 20,
  }) async {
    final res = await _dio.safeGet<dynamic>(
      ApiEndpoints.fortuneTellerReviews(id),
      query: apiPageQuery(page: page, limit: limit),
    );
    return ServiceUtils.extractList(
      res.data,
      keys: const ['reviews', 'items', 'data'],
    );
  }

  /// `POST /api/fortune-tellers/{tellerId}/session`
  Future<Map<String, dynamic>> requestSession(
    String tellerId, {
    String? fortuneType,
    int? maxMinutes,
  }) async {
    final res = await _dio.safePost<dynamic>(
      ApiEndpoints.fortuneTellerSessionFor(tellerId),
      data: {
        if (fortuneType != null && fortuneType.isNotEmpty)
          'fortuneType': fortuneType,
        if (maxMinutes != null) 'maxMinutes': maxMinutes,
      },
    );
    return ServiceUtils.unwrapMap(res.data) ?? asJsonMap(res.data);
  }

  /// `GET /api/favorite-tellers`
  Future<List<Map<String, dynamic>>> getFavorites() async {
    final res = await _dio.safeGet<dynamic>(ApiEndpoints.favoriteTellers);
    return ServiceUtils.extractList(
      res.data,
      keys: const ['tellers', 'favorites', 'items', 'data'],
    );
  }

  /// `POST /api/favorite-tellers` — `{tellerId}`.
  Future<Map<String, dynamic>> toggleFavorite(String tellerId) async {
    final res = await _dio.safePost<dynamic>(
      ApiEndpoints.favoriteTellers,
      data: {'tellerId': tellerId},
    );
    return ServiceUtils.unwrapMap(res.data) ?? asJsonMap(res.data);
  }
}
