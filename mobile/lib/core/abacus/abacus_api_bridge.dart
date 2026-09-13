import 'package:dio/dio.dart';

import '../network/dio_provider.dart';
import '../util/json_util.dart';

/// Doğrulanmış Abacus uçları için ince JSON köprüsü (şema MISSING → ham Map).
class AbacusApiBridge {
  AbacusApiBridge(this._dio);

  final Dio _dio;

  Future<Map<String, dynamic>> getJson(
    String path, {
    Map<String, dynamic>? query,
  }) async {
    final res = await _dio.safeGet<dynamic>(path, query: query);
    return _asMap(res.data);
  }

  Future<Map<String, dynamic>> postJson(
    String path, {
    Object? data,
    Map<String, dynamic>? query,
  }) async {
    final res = await _dio.safePost<dynamic>(path, data: data, query: query);
    return _asMap(res.data);
  }

  Future<Map<String, dynamic>> patchJson(
    String path, {
    Object? data,
    Map<String, dynamic>? query,
  }) async {
    final res = await _dio.safePatch<dynamic>(path, data: data, query: query);
    return _asMap(res.data);
  }

  Future<Map<String, dynamic>> deleteJson(
    String path, {
    Map<String, dynamic>? query,
  }) async {
    final res = await _dio.safeDelete<dynamic>(path, query: query);
    if (res.data is Map) {
      return Map<String, dynamic>.from(res.data as Map);
    }
    return {};
  }

  Map<String, dynamic> _asMap(dynamic data) {
    if (data is Map) {
      return asJsonMap(data);
    }
    return {};
  }
}
