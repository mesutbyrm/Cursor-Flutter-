import 'package:dio/dio.dart';

import '../../../../core/network/api_endpoints.dart';
import '../../../../core/network/dio_provider.dart';
import '../../../../core/util/json_util.dart';
import '../../domain/entities/social_discovery_user.dart';
import '../../domain/entities/user_location_settings.dart';

/// Abacus BÖLÜM 21/A6 — Tanış & Kaynaş (`discovery`, `actions`, `user/location`).
class SocialDiscoveryRemoteDataSource {
  SocialDiscoveryRemoteDataSource(this._dio);

  final Dio _dio;

  Future<List<SocialDiscoveryUser>> fetchDiscovery() async {
    final res = await _dio.safeGet<dynamic>(ApiEndpoints.socialDiscovery);
    return _parseUsers(res.data);
  }

  Future<List<Map<String, dynamic>>> fetchActions() async {
    final res = await _dio.safeGet<dynamic>(ApiEndpoints.socialActions);
    return _parseActionRows(res.data);
  }

  Future<Map<String, dynamic>> postAction({
    required String type,
    required String targetId,
    String? message,
  }) async {
    final res = await _dio.safePost<Map<String, dynamic>>(
      ApiEndpoints.socialActions,
      data: {
        'type': type,
        'targetId': targetId,
        if (message != null && message.isNotEmpty) 'message': message,
      },
    );
    return asJsonMap(res.data);
  }

  Future<UserLocationSettings> fetchLocationSettings() async {
    final res = await _dio.safeGet<dynamic>(ApiEndpoints.userLocation);
    final map = res.data is Map
        ? Map<String, dynamic>.from(res.data as Map)
        : <String, dynamic>{};
    return UserLocationSettings.fromJson(map);
  }

  Future<UserLocationSettings> updateLocationSettings(
    Map<String, dynamic> body,
  ) async {
    final res = await _dio.safePost<dynamic>(
      ApiEndpoints.userLocation,
      data: body,
    );
    final map = res.data is Map
        ? Map<String, dynamic>.from(res.data as Map)
        : <String, dynamic>{};
    return UserLocationSettings.fromJson(map);
  }

  List<SocialDiscoveryUser> _parseUsers(dynamic body) {
    final root = _unwrap(body);
    final list = pick(root, [
      'users',
      'candidates',
      'items',
      'results',
      'discovery',
      'data',
    ]);
    if (list is List) {
      return list
          .whereType<Map>()
          .map((e) => SocialDiscoveryUser.fromJson(Map<String, dynamic>.from(e)))
          .where((u) => u.id.isNotEmpty)
          .toList(growable: false);
    }
    if (root['users'] is List) {
      return asJsonList(root['users'])
          .map(SocialDiscoveryUser.fromJson)
          .where((u) => u.id.isNotEmpty)
          .toList(growable: false);
    }
    return const [];
  }

  List<Map<String, dynamic>> _parseActionRows(dynamic body) {
    final root = _unwrap(body);
    final list = pick(root, ['actions', 'items', 'data']);
    if (list is List) {
      return list
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList(growable: false);
    }
    return const [];
  }

  Map<String, dynamic> _unwrap(dynamic body) {
    if (body is Map) {
      return Map<String, dynamic>.from(body);
    }
    return {};
  }
}
