import 'package:dio/dio.dart';

import '../../../core/config/env.dart';
import '../../../core/network/api_endpoints.dart';
import '../../../core/network/dio_provider.dart';
import '../../../core/util/json_util.dart';
import '../domain/gift_entity.dart';
import '../domain/gift_leaderboard_entry.dart';
import '../domain/gift_platform.dart';

class GiftRepository {
  GiftRepository(this._dio);

  final Dio _dio;

  Future<List<GiftEntity>> fetchCatalog({
    GiftPlatform platform = GiftPlatform.mobile,
  }) async {
    final res = await _dio.safeGet<dynamic>(
      ApiEndpoints.videoStreamGiftsCatalog,
      query: {'platform': platform.queryValue},
    );
    return _parseCatalogList(res.data);
  }

  Future<List<GiftEntity>> fetchCatalogV2({
    GiftPlatform platform = GiftPlatform.mobile,
  }) async {
    final res = await _dio.safeGet<dynamic>(
      '/api/gifts',
      query: {'platform': platform.queryValue},
    );
    return _parseCatalogList(_unwrap(res.data));
  }

  Future<List<GiftLeaderboardEntry>> fetchLeaderboard(String streamId) async {
    final res = await _dio.safeGet<dynamic>(
      ApiEndpoints.videoStreamGiftLeaderboard(streamId),
    );
    final body = _unwrap(res.data);
    if (body is Map) {
      final leaders = body['leaders'];
      if (leaders is List) {
        return leaders
            .map((e) => GiftLeaderboardEntry.fromJson(asJsonMap(e)))
            .toList();
      }
    }
    return const [];
  }

  List<GiftEntity> _parseCatalogList(dynamic data) {
    final list = _unwrap(data);
    if (list is! List) return const [];
    return list
        .map((e) => GiftEntity.fromJson(asJsonMap(e), siteOrigin: Env.siteOrigin))
        .where((g) => g.id.isNotEmpty)
        .toList();
  }

  dynamic _unwrap(dynamic data) {
    if (data is Map && data['success'] == true && data['data'] != null) {
      return data['data'];
    }
    return data;
  }
}
