import 'package:dio/dio.dart';

import '../../../../core/network/api_endpoints.dart';
import '../../../../core/network/dio_provider.dart';
import '../../../../core/util/json_util.dart';
import '../../domain/entities/social_discovery_user.dart';
import '../../domain/entities/user_location_settings.dart';

/// Abacus §11 Sosyal & Keşif + BÖLÜM 21/A6 konum (`TUM_OZELLIKLER_HARITASI`).
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

  Future<Map<String, dynamic>> fetchSocialProfile({String? userId}) async {
    final res = await _dio.safeGet<dynamic>(
      ApiEndpoints.socialProfile,
      query: {if (userId != null && userId.isNotEmpty) 'userId': userId},
    );
    return asJsonMap(res.data);
  }

  Future<Map<String, dynamic>> fetchShareCard({
    String? fortuneId,
    String? postId,
  }) async {
    final res = await _dio.safeGet<dynamic>(
      ApiEndpoints.shareCard,
      query: {
        if (fortuneId != null && fortuneId.isNotEmpty) 'fortuneId': fortuneId,
        if (postId != null && postId.isNotEmpty) 'postId': postId,
      },
    );
    return asJsonMap(res.data);
  }

  Future<Map<String, dynamic>> fetchHashtag(String name) async {
    final res = await _dio.safeGet<dynamic>(ApiEndpoints.hashtagByName(name));
    return asJsonMap(res.data);
  }

  Future<Map<String, dynamic>> searchHashtags({required String q}) async {
    final res = await _dio.safeGet<dynamic>(
      ApiEndpoints.hashtagsSearch,
      query: {'q': q},
    );
    return asJsonMap(res.data);
  }

  Future<Map<String, dynamic>> fetchTrendingHashtags() async {
    final res = await _dio.safeGet<dynamic>(ApiEndpoints.hashtagsTrending);
    return asJsonMap(res.data);
  }

  Future<Map<String, dynamic>> fetchTeams() async {
    final res = await _dio.safeGet<dynamic>(ApiEndpoints.teams);
    return asJsonMap(res.data);
  }

  Future<Map<String, dynamic>> fetchTeam(String teamId) async {
    final res = await _dio.safeGet<dynamic>(ApiEndpoints.teamById(teamId));
    return asJsonMap(res.data);
  }

  Future<Map<String, dynamic>> createTeam(Map<String, dynamic> body) async {
    final res = await _dio.safePost<dynamic>(ApiEndpoints.teams, data: body);
    return asJsonMap(res.data);
  }

  Future<Map<String, dynamic>> patchTeam(
    String teamId,
    Map<String, dynamic> body,
  ) async {
    final res = await _dio.safePatch<dynamic>(
      ApiEndpoints.teamById(teamId),
      data: body,
    );
    return asJsonMap(res.data);
  }
}
