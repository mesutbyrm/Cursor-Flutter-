import 'package:dio/dio.dart';

import '../../../../core/network/api_endpoints.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/network/dio_provider.dart';
import '../../../../core/util/json_util.dart';
import '../../domain/fortune_access_config.dart';

class FortuneAccessRemoteDataSource {
  FortuneAccessRemoteDataSource(this._dio);

  final Dio _dio;

  Future<FortuneAccessConfig?> fetchSettings() async {
    for (final path in [
      ApiEndpoints.fortuneAccessIpStatus,
      ApiEndpoints.fortuneAccessSettings,
    ]) {
      try {
        final res = await _dio.safeGet<dynamic>(path);
        final data = res.data;
        if (data is! Map) continue;
        final map = _unwrap(data);
        if (map.isEmpty) continue;
        return FortuneAccessConfig.fromJson(map);
      } catch (_) {
        continue;
      }
    }
    return null;
  }

  /// Kılavuz §9.5 / OpenAPI — POST `/api/fortune-access/check`.
  Future<Map<String, dynamic>?> checkAccess({required String fortuneType}) async {
    try {
      final res = await _dio.safePost<dynamic>(
        ApiEndpoints.fortuneAccessCheck,
        data: {'fortuneType': fortuneType},
      );
      if (res.data is! Map) return null;
      return _unwrap(res.data);
    } catch (_) {
      return null;
    }
  }

  /// Reklam izlendikten sonra +1 fal hakkı (veya sunucunun verdiği miktar).
  Future<int> rewardFortuneAdCredit({required String slug}) async {
    final res = await _dio.safePost<dynamic>(
      ApiEndpoints.userWatchAd,
      data: {
        'platform': 'mobile',
        'source': 'fortune_ad_reward',
        'fortuneSlug': slug,
        'rewardType': 'fortune_credit',
      },
    );
    return _parseReward(res.data);
  }

  /// Jeton ön doğrulama — kanonik `POST /api/fortune-access/check` (jeton düşümü fal POST).
  Future<void> consumeJetonAccess({
    required String slug,
    required int jetonCost,
  }) async {
    await _postFortuneAccessPreflight(body: {
      'fortuneType': slug,
      'method': 'jeton',
      'jetonCost': jetonCost,
      'platform': 'mobile',
    });
  }

  Future<void> consumeCfcAccess({
    required String slug,
    required int cfcCost,
  }) async {
    await _postFortuneAccessPreflight(body: {
        'fortuneType': slug,
        'method': 'cfc',
        'cfcCost': cfcCost,
        'platform': 'mobile',
      },
    );
  }

  Future<void> _postFortuneAccessPreflight({
    required Map<String, dynamic> body,
  }) async {
    try {
      await _dio.safePost<dynamic>(
        ApiEndpoints.fortuneAccessCheck,
        data: body,
      );
    } on ApiException catch (e) {
      if (e.statusCode == 404 || e.statusCode == 405) return;
      rethrow;
    }
  }

  int _parseReward(dynamic body) {
    if (body is! Map) return 1;
    final map = _unwrap(body);
    final credits = asInt(
      pick(map, [
        'fortuneAdCredits',
        'fortuneCredits',
        'adCredits',
        'creditsEarned',
        'reward',
        'amount',
      ]),
    );
    if (credits > 0) return credits;
    final granted = asInt(pick(map, ['granted', 'added']));
    return granted > 0 ? granted : 1;
  }

  Map<String, dynamic> _unwrap(dynamic data) {
    if (data is! Map) return {};
    final map = Map<String, dynamic>.from(data);
    final inner = map['data'];
    if (inner is Map) return Map<String, dynamic>.from(inner);
    return map;
  }
}
