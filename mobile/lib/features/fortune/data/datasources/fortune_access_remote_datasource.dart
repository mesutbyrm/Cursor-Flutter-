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
    try {
      final res = await _dio.safeGet<dynamic>(ApiEndpoints.fortuneAccessSettings);
      final data = res.data;
      if (data is! Map) return null;
      final map = _unwrap(data);
      return FortuneAccessConfig.fromJson(map);
    } catch (_) {
      return null;
    }
  }

  /// Kılavuz §9.5 — fal açılmadan önce erişim kontrolü.
  Future<Map<String, dynamic>?> checkAccess({required String fortuneType}) async {
    try {
      final res = await _dio.safeGet<dynamic>(
        ApiEndpoints.fortuneAccessCheck,
        query: {'fortuneType': fortuneType},
        forceRefresh: true,
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

  /// Jeton ile fal kilidi — sunucu jeton düşerse burada doğrulanır.
  Future<void> consumeJetonAccess({
    required String slug,
    required int jetonCost,
  }) async {
    try {
      await _dio.safePost<dynamic>(
        ApiEndpoints.fortuneAccessConsume,
        data: {
          'slug': slug,
          'method': 'jeton',
          'jetonCost': jetonCost,
          'platform': 'mobile',
        },
      );
    } on ApiException catch (e) {
      if (e.statusCode == 404) return;
      rethrow;
    }
  }

  Future<void> consumeCfcAccess({
    required String slug,
    required int cfcCost,
  }) async {
    try {
      await _dio.safePost<dynamic>(
        ApiEndpoints.fortuneAccessConsume,
        data: {
          'slug': slug,
          'method': 'cfc',
          'cfcCost': cfcCost,
          'platform': 'mobile',
        },
      );
    } on ApiException catch (e) {
      if (e.statusCode == 404) return;
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
