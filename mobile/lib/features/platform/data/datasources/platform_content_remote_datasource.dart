import 'package:dio/dio.dart';

import '../../../../core/network/api_endpoints.dart';
import '../../../../core/network/dio_provider.dart';
import '../../../../core/util/json_util.dart';
import '../models/fortune_request_type.dart';
import '../models/platform_ad.dart';
import '../models/platform_popup.dart';

/// Platform içerik uçları — popup, reklam, fal türü kataloğu.
class PlatformContentRemoteDataSource {
  PlatformContentRemoteDataSource(this._dio);

  final Dio _dio;

  Future<List<PlatformPopup>> fetchPopups() async {
    try {
      final res = await _dio.safeGet<dynamic>(ApiEndpoints.popups);
      return _parseList(res.data, PlatformPopup.fromJson, keys: [
        'popups',
        'items',
        'data',
      ]);
    } catch (_) {
      return const [];
    }
  }

  Future<List<PlatformAd>> fetchActiveAds() async {
    try {
      final res = await _dio.safeGet<dynamic>(ApiEndpoints.adsActive);
      return _parseList(res.data, PlatformAd.fromJson, keys: [
        'ads',
        'items',
        'data',
        'active',
      ]);
    } catch (_) {
      return const [];
    }
  }

  Future<bool> claimAdReward({String? adId, String? placement}) async {
    final body = <String, dynamic>{};
    if (adId != null && adId.trim().isNotEmpty) body['adId'] = adId.trim();
    if (placement != null && placement.trim().isNotEmpty) {
      body['placement'] = placement.trim();
    }
    final res = await _dio.safePost<dynamic>(
      ApiEndpoints.adsReward,
      data: body.isEmpty ? null : body,
    );
    final data = res.data;
    if (data is Map) {
      if (data['success'] == false) return false;
      return data['success'] == true || data['rewarded'] == true;
    }
    return res.statusCode == 200 || res.statusCode == 201;
  }

  Future<List<FortuneRequestType>> fetchFortuneRequestTypes() async {
    try {
      final res = await _dio.safeGet<dynamic>(ApiEndpoints.fortuneRequestTypes);
      return _parseList(res.data, FortuneRequestType.fromJson, keys: [
        'types',
        'items',
        'data',
        'fortuneRequestTypes',
      ]);
    } catch (_) {
      return const [];
    }
  }

  List<T> _parseList<T>(
    dynamic body,
    T Function(Map<String, dynamic>) fromJson, {
    List<String> keys = const ['items', 'data'],
  }) {
    dynamic list;
    if (body is Map) {
      final map = Map<String, dynamic>.from(body);
      for (final key in keys) {
        final candidate = map[key];
        if (candidate is List) {
          list = candidate;
          break;
        }
      }
      list ??= map['data'] is List ? map['data'] : null;
    } else {
      list = body;
    }
    if (list is! List) return const [];
    return list
        .whereType<Map>()
        .map((e) => fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }
}
