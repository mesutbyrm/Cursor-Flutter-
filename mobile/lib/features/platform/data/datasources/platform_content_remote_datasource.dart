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

  /// `GET /api/announcements` — site duyuruları (kılavuz §9.13).
  Future<List<PlatformPopup>> fetchAnnouncements() async {
    final res = await _dio.safeGet<dynamic>(ApiEndpoints.announcements);
    return _parseList(res.data, PlatformPopup.fromJson, keys: [
      'announcements',
      'items',
      'data',
      'banners',
    ]).where((p) => p.title.trim().isNotEmpty).toList();
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
    final res = await _dio.safeGet<dynamic>(ApiEndpoints.fortuneRequestTypes);
    return _parseList(res.data, FortuneRequestType.fromJson, keys: [
      'types',
      'items',
      'data',
      'fortuneRequestTypes',
    ]);
  }

  /// `GET /api/broadcast-images` — yayın arka plan görselleri.
  Future<List<Map<String, dynamic>>> fetchBroadcastImages() async {
    return _fetchJsonList(ApiEndpoints.broadcastImages, keys: const [
      'images',
      'items',
      'data',
    ]);
  }

  /// `GET /api/football` — canlı futbol skorları.
  Future<List<Map<String, dynamic>>> fetchFootball() async {
    return _fetchJsonList(ApiEndpoints.football, keys: const [
      'matches',
      'items',
      'data',
      'football',
    ]);
  }

  /// `GET /api/online-fal` — online fal bölümleri.
  Future<List<Map<String, dynamic>>> fetchOnlineFal() async {
    return _fetchJsonList(ApiEndpoints.onlineFal, keys: const [
      'sections',
      'items',
      'data',
      'categories',
    ]);
  }

  /// `GET /api/translations?lang=tr` — uygulama çevirileri.
  Future<Map<String, String>> fetchTranslations({String lang = 'tr'}) async {
    try {
      final res = await _dio.safeGet<dynamic>(
        ApiEndpoints.translations(lang: lang),
      );
      final body = res.data;
      if (body is Map) {
        final map = Map<String, dynamic>.from(body);
        final data = map['data'] ?? map['translations'] ?? map;
        if (data is Map) {
          return data.map(
            (k, v) => MapEntry(k.toString(), v?.toString() ?? ''),
          );
        }
      }
      return const {};
    } catch (_) {
      return const {};
    }
  }

  /// `GET /api/user/likers` — profili beğenenler.
  Future<List<Map<String, dynamic>>> fetchUserLikers() async {
    return _fetchJsonList(ApiEndpoints.userLikers, keys: const [
      'likers',
      'users',
      'items',
      'data',
    ]);
  }

  /// `GET /api/users/online` — çevrimiçi kullanıcılar (kılavuz §9.2).
  Future<List<Map<String, dynamic>>> fetchOnlineUsers() async {
    return _fetchJsonList(ApiEndpoints.usersOnline, keys: const [
      'users',
      'online',
      'items',
      'data',
      'onlineUsers',
    ]);
  }

  Future<List<Map<String, dynamic>>> _fetchJsonList(
    String path, {
    List<String> keys = const ['items', 'data'],
  }) async {
    final res = await _dio.safeGet<dynamic>(path);
    final body = res.data;
    dynamic list;
    if (body is Map) {
      final map = Map<String, dynamic>.from(body);
      if (map['success'] == true && map['data'] != null) {
        return _fetchJsonListFromDynamic(map['data'], keys: keys);
      }
      for (final key in keys) {
        final candidate = map[key];
        if (candidate is List) return asJsonList(candidate);
      }
      list = map['data'];
    } else {
      list = body;
    }
    return _fetchJsonListFromDynamic(list, keys: keys);
  }

  List<Map<String, dynamic>> _fetchJsonListFromDynamic(
    dynamic list, {
    List<String> keys = const ['items', 'data'],
  }) {
    if (list is List) {
      return list.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
    }
    if (list is Map) {
      final map = Map<String, dynamic>.from(list);
      for (final key in keys) {
        final candidate = map[key];
        if (candidate is List) {
          return candidate
              .whereType<Map>()
              .map((e) => Map<String, dynamic>.from(e))
              .toList();
        }
      }
    }
    return const [];
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
