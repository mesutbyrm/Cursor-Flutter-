import 'package:dio/dio.dart';

import '../../../core/config/env.dart';
import '../../../core/network/api_endpoints.dart';
import '../../../core/network/dio_provider.dart';
import '../../../core/util/json_util.dart';
import '../domain/gift_entity.dart';
import '../domain/gift_platform.dart';
import '../domain/lucky_gift_entities.dart';

class LuckyGiftRemoteDataSource {
  LuckyGiftRemoteDataSource(this._dio);

  final Dio _dio;

  Future<LuckyGiftConfig> fetchConfig() async {
    final res = await _dio.safeGet<dynamic>(ApiEndpoints.giftsLuckyConfig);
    final body = _unwrap(res.data);
    if (body is! Map) {
      return const LuckyGiftConfig();
    }
    return LuckyGiftConfig.fromJson(asJsonMap(body));
  }

  Future<LuckyGiftSpinResult> sendLuckyGift({
    required String giftTypeId,
    int quantity = 1,
    String? context,
    String? contextId,
  }) async {
    final res = await _dio.safePost<dynamic>(
      ApiEndpoints.giftsLuckySend,
      data: {
        'giftTypeId': giftTypeId,
        'quantity': quantity,
        if (context != null && context.isNotEmpty) 'context': context,
        if (contextId != null && contextId.isNotEmpty) 'contextId': contextId,
      },
    );
    final body = _unwrap(res.data);
    if (body is! Map) {
      throw const FormatException('Şanslı hediye yanıtı geçersiz');
    }
    return LuckyGiftSpinResult.fromJson(asJsonMap(body));
  }

  Future<({LuckyGiftHistorySummary? summary, List<LuckyGiftHistoryEntry> items})>
      fetchHistory({
    String scope = 'me',
    int? limit,
  }) async {
    final res = await _dio.safeGet<dynamic>(
      ApiEndpoints.giftsLuckyHistory,
      query: {
        'scope': scope,
        if (limit != null) 'limit': limit,
      },
    );
    final body = _unwrap(res.data);
    if (body is! Map) {
      return (summary: null, items: <LuckyGiftHistoryEntry>[]);
    }
    final map = asJsonMap(body);
    if (scope == 'global') {
      final feed = pick(map, ['feed']);
      final items = feed is List
          ? feed
              .whereType<Map>()
              .map((e) => LuckyGiftHistoryEntry.fromJson(asJsonMap(e)))
              .toList()
          : <LuckyGiftHistoryEntry>[];
      return (summary: null, items: items);
    }
    final summaryRaw = pick(map, ['summary']);
    final historyRaw = pick(map, ['history']);
    return (
      summary: summaryRaw is Map
          ? LuckyGiftHistorySummary.fromJson(asJsonMap(summaryRaw))
          : null,
      items: historyRaw is List
          ? historyRaw
              .whereType<Map>()
              .map((e) => LuckyGiftHistoryEntry.fromJson(asJsonMap(e)))
              .toList()
          : <LuckyGiftHistoryEntry>[],
    );
  }

  Future<GiftCatalogVersionInfo> fetchCatalogVersion() async {
    final res = await _dio.safeGet<dynamic>(ApiEndpoints.giftsVersion);
    final body = _unwrap(res.data);
    if (body is! Map) return const GiftCatalogVersionInfo();
    return GiftCatalogVersionInfo.fromJson(asJsonMap(body));
  }

  Future<List<GiftEntity>> fetchCatalogCms({
    int? sinceVersion,
    String? context,
    GiftPlatform platform = GiftPlatform.mobile,
  }) async {
    final res = await _dio.safeGet<dynamic>(
      ApiEndpoints.giftsCatalogCms,
      query: {
        if (sinceVersion != null) 'sinceVersion': sinceVersion,
        if (context != null && context.isNotEmpty) 'context': context,
        'platform': platform.queryValue,
      },
    );
    final body = _unwrap(res.data);
    if (body is! Map) return const [];
    final giftsRaw = pick(asJsonMap(body), ['gifts']);
    if (giftsRaw is! List) return const [];
    return giftsRaw
        .whereType<Map>()
        .map(
          (e) => GiftEntity.fromJson(
            asJsonMap(e),
            siteOrigin: Env.siteOrigin,
          ),
        )
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
