import 'package:dio/dio.dart';

import '../core/network/api_endpoints.dart';
import '../core/network/dio_provider.dart';
import '../core/util/json_util.dart';
import 'service_utils.dart';

/// Ana sayfa, duyuru, liderlik ve günlük ödül API — kılavuz §9.13.
class MiscService {
  MiscService({required Dio Function() resolveAuthedDio})
      : _resolveAuthedDio = resolveAuthedDio;

  final Dio Function() _resolveAuthedDio;
  Dio get _dio => _resolveAuthedDio();

  /// `GET /api/homepage-buttons`
  Future<List<Map<String, dynamic>>> getHomepageButtons() async {
    final res = await _dio.safeGet<dynamic>(ApiEndpoints.homepageButtons);
    return ServiceUtils.extractList(
      res.data,
      keys: const ['buttons', 'items', 'data'],
    );
  }

  /// `GET /api/announcements`
  Future<List<Map<String, dynamic>>> getAnnouncements() async {
    final res = await _dio.safeGet<dynamic>(ApiEndpoints.announcements);
    return ServiceUtils.extractList(
      res.data,
      keys: const ['announcements', 'items', 'data'],
    );
  }

  /// `GET /api/leaderboard` veya `/api/leaderboards`
  Future<List<Map<String, dynamic>>> getLeaderboard({
    String? type,
    String? period,
  }) async {
    final query = <String, dynamic>{
      if (type != null && type.isNotEmpty) 'type': type,
      if (period != null && period.isNotEmpty) 'period': period,
    };
    try {
      final res = await _dio.safeGet<dynamic>(
        ApiEndpoints.leaderboard,
        query: query.isEmpty ? null : query,
      );
      return ServiceUtils.extractList(
        res.data,
        keys: const ['leaderboard', 'entries', 'items', 'data'],
      );
    } catch (_) {
      final res = await _dio.safeGet<dynamic>(
        ApiEndpoints.leaderboards,
        query: query.isEmpty ? null : query,
      );
      return ServiceUtils.extractList(res.data);
    }
  }

  /// `POST /api/horoscope/daily` — kılavuz §9.5; GET yedek.
  Future<Map<String, dynamic>> getDailyHoroscope(String sign) async {
    try {
      final res = await _dio.safePost<dynamic>(
        ApiEndpoints.horoscopeDaily,
        data: {'zodiacSign': sign, 'sign': sign},
      );
      return ServiceUtils.unwrapMap(res.data) ?? asJsonMap(res.data);
    } catch (_) {
      final res = await _dio.safeGet<dynamic>(
        ApiEndpoints.horoscopeDaily,
        query: {'sign': sign, 'zodiacSign': sign},
      );
      return ServiceUtils.unwrapMap(res.data) ?? asJsonMap(res.data);
    }
  }

  /// `GET /api/daily-login`
  Future<Map<String, dynamic>> getDailyLogin() async {
    final res = await _dio.safeGet<dynamic>(ApiEndpoints.dailyLogin);
    return ServiceUtils.unwrapMap(res.data) ?? asJsonMap(res.data);
  }

  /// `POST /api/daily-login`
  Future<Map<String, dynamic>> claimDailyLogin() async {
    final res = await _dio.safePost<dynamic>(ApiEndpoints.dailyLogin);
    return ServiceUtils.unwrapMap(res.data) ?? asJsonMap(res.data);
  }

  /// `POST /api/user/watch-ad`
  Future<Map<String, dynamic>> watchAd() async {
    final res = await _dio.safePost<dynamic>(ApiEndpoints.userWatchAd);
    return ServiceUtils.unwrapMap(res.data) ?? asJsonMap(res.data);
  }

  /// `GET /api/referral`
  Future<Map<String, dynamic>> getReferral() async {
    final res = await _dio.safeGet<dynamic>(ApiEndpoints.referral);
    return ServiceUtils.unwrapMap(res.data) ?? asJsonMap(res.data);
  }
}
