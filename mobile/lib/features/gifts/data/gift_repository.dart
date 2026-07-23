import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/config/env.dart';
import '../../../core/network/api_endpoints.dart';
import '../../../core/network/dio_provider.dart';
import '../../../core/util/json_util.dart';
import 'gift_cache_service.dart';
import '../domain/gift_entity.dart';
import '../domain/gift_leaderboard_entry.dart';
import '../domain/gift_platform.dart';
import '../domain/lucky_gift_entities.dart';
import 'gift_catalog_sync_cache.dart';
import 'lucky_gift_remote_datasource.dart';

class GiftRepository {
  GiftRepository(this._dio, {LuckyGiftRemoteDataSource? luckyDs}) 
      : _luckyDs = luckyDs ?? LuckyGiftRemoteDataSource(_dio);

  final Dio _dio;
  final LuckyGiftRemoteDataSource _luckyDs;
  GiftCatalogSyncCache? _cache;

  Future<GiftCatalogSyncCache> _syncCache() async {
    _cache ??= GiftCatalogSyncCache(await SharedPreferences.getInstance());
    return _cache!;
  }

  LuckyGiftRemoteDataSource get lucky => _luckyDs;

  Future<List<GiftEntity>> fetchCatalog({
    GiftPlatform platform = GiftPlatform.mobile,
    String? context,
    bool forceRefresh = false,
  }) async {
    try {
      final synced = await syncCatalogIfNeeded(
        platform: platform,
        context: context,
        forceRefresh: forceRefresh,
      );
      if (synced.isNotEmpty) return synced;
    } catch (_) {}
    try {
      final cms = await _luckyDs.fetchCatalogCms(
        platform: platform,
        context: context,
      );
      if (cms.isNotEmpty) return cms;
    } catch (_) {}
    final res = await _dio.safeGet<dynamic>(
      ApiEndpoints.videoStreamGiftsCatalog,
      query: {'platform': platform.queryValue},
    );
    final legacy = _parseCatalogList(res.data);
    if (legacy.isNotEmpty) return legacy;
    return fetchCatalogV2(platform: platform);
  }

  /// CMS versiyon kontrolü + delta senkronizasyon.
  Future<List<GiftEntity>> syncCatalogIfNeeded({
    GiftPlatform platform = GiftPlatform.mobile,
    String? context,
    bool forceRefresh = false,
  }) async {
    final cache = await _syncCache();
    final remoteVersion = await _luckyDs.fetchCatalogVersion();
    final localVersion = cache.readVersion();
    if (!forceRefresh &&
        remoteVersion.giftVersion > 0 &&
        remoteVersion.giftVersion <= localVersion) {
      final cached = cache.readCatalog(siteOrigin: Env.siteOrigin);
      if (cached.isNotEmpty) return cached;
    }
    final gifts = await _luckyDs.fetchCatalogCms(
      sinceVersion:
          !forceRefresh && localVersion > 0 ? localVersion : null,
      context: context,
      platform: platform,
    );
    if (gifts.isEmpty) {
      final cached = cache.readCatalog(siteOrigin: Env.siteOrigin);
      return cached;
    }
    List<GiftEntity> merged;
    if (!forceRefresh &&
        localVersion > 0 &&
        remoteVersion.giftVersion > localVersion) {
      final existing = {
        for (final g in cache.readCatalog(siteOrigin: Env.siteOrigin)) g.id: g,
      };
      for (final g in gifts) {
        existing[g.id] = g;
      }
      merged = existing.values.toList()
        ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    } else {
      merged = gifts;
    }
    await cache.writeCatalog(merged);
    if (remoteVersion.giftVersion > 0) {
      await cache.writeVersion(remoteVersion.giftVersion);
    }
    GiftCacheService.instance.prefetchUrls(
      merged.map((g) => g.networkAnimationUrl).whereType<String>(),
    );
    return merged;
  }

  Future<GiftCatalogVersionInfo> fetchCatalogVersion() =>
      _luckyDs.fetchCatalogVersion();

  /// Admin kaydı sonrası — disk önbelleğini sıfırla, sonraki istek tam senkron.
  Future<void> bustCatalogCache() async {
    final cache = await _syncCache();
    await cache.clear();
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

  /// Kılavuz §9.9 — karşılıklı hediye kontrolü (`GET ?userId=`).
  Future<Map<String, dynamic>> checkReciprocal(String userId) async {
    final res = await _dio.safeGet<dynamic>(
      ApiEndpoints.giftsCheckReciprocal,
      query: {'userId': userId.trim()},
    );
    final body = _unwrap(res.data);
    if (body is Map) return Map<String, dynamic>.from(body);
    return const {};
  }
}
