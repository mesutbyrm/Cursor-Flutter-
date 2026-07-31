import 'package:dio/dio.dart';

import '../../../../core/network/api_endpoints.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/network/dio_provider.dart';
import '../../../../core/util/service_utils.dart';
import '../models/mobile_compound_models.dart';

/// Mobil birleşik endpoint'ler — `GET /api/mobile/*`.
class MobileCompoundRemoteDataSource {
  MobileCompoundRemoteDataSource(this._dio);

  final Dio _dio;

  MobileHomeBundle? _homeCache;
  DateTime? _homeFetchedAt;
  static const _homeTtl = Duration(seconds: 45);

  MobileFortuneMenuBundle? _fortuneMenuCache;
  DateTime? _fortuneMenuFetchedAt;
  static const _fortuneMenuTtl = Duration(minutes: 2);

  /// `GET /api/mobile/home`
  Future<MobileHomeBundle?> fetchHome({bool force = false}) async {
    if (!force &&
        _homeCache != null &&
        _homeFetchedAt != null &&
        DateTime.now().difference(_homeFetchedAt!) < _homeTtl) {
      return _homeCache;
    }
    try {
      final res = await _dio.safeGet<dynamic>(ApiEndpoints.mobileHome);
      final map = ServiceUtils.unwrapMap(res.data);
      if (map == null || map.isEmpty) return null;
      final bundle = MobileHomeBundle.fromJson(map);
      _homeCache = bundle;
      _homeFetchedAt = DateTime.now();
      return bundle;
    } on ApiException catch (e) {
      if (e.statusCode == 404 || e.statusCode == 405) return null;
      rethrow;
    } catch (_) {
      return null;
    }
  }

  /// `GET /api/mobile/fortune-menu`
  Future<MobileFortuneMenuBundle?> fetchFortuneMenu({bool force = false}) async {
    if (!force &&
        _fortuneMenuCache != null &&
        _fortuneMenuFetchedAt != null &&
        DateTime.now().difference(_fortuneMenuFetchedAt!) < _fortuneMenuTtl) {
      return _fortuneMenuCache;
    }
    try {
      final res = await _dio.safeGet<dynamic>(ApiEndpoints.mobileFortuneMenu);
      final map = ServiceUtils.unwrapMap(res.data);
      if (map == null || map.isEmpty) return null;
      final bundle = MobileFortuneMenuBundle.fromJson(map);
      _fortuneMenuCache = bundle;
      _fortuneMenuFetchedAt = DateTime.now();
      return bundle;
    } on ApiException catch (e) {
      if (e.statusCode == 404 || e.statusCode == 405) return null;
      rethrow;
    } catch (_) {
      return null;
    }
  }

  /// `GET /api/mobile/user-profile/{userId}`
  Future<MobileUserProfileBundle?> fetchUserProfile(String userId) async {
    final id = userId.trim();
    if (id.isEmpty) return null;
    try {
      final res =
          await _dio.safeGet<dynamic>(ApiEndpoints.mobileUserProfile(id));
      final map = ServiceUtils.unwrapMap(res.data);
      if (map == null || map.isEmpty) return null;
      return MobileUserProfileBundle.fromJson(map);
    } on ApiException catch (e) {
      if (e.statusCode == 404 || e.statusCode == 405) return null;
      rethrow;
    } catch (_) {
      return null;
    }
  }

  void invalidateHomeCache() {
    _homeCache = null;
    _homeFetchedAt = null;
  }
}
