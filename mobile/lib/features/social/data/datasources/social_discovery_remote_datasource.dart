import 'package:dio/dio.dart';

import '../../../../core/network/api_endpoints.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/network/dio_provider.dart';
import '../../../../core/util/json_util.dart';
import '../../domain/entities/social_discovery_feed.dart';
import '../../domain/entities/social_discovery_user.dart';
import '../../domain/entities/user_location_settings.dart';

/// Abacus §11 Sosyal & Keşif + BÖLÜM 21/A6 konum (`TUM_OZELLIKLER_HARITASI`).
class SocialDiscoveryRemoteDataSource {
  SocialDiscoveryRemoteDataSource(this._dio);

  final Dio _dio;

  Future<SocialDiscoveryFeed> fetchDiscovery({
    int page = 1,
    int limit = 20,
    int? minAge,
    int? maxAge,
    String? city,
    bool? onlineOnly,
    String? gender,
    String? membership,
    String? interest,
  }) async {
    final query = <String, dynamic>{
      'page': page,
      'limit': limit,
      if (minAge != null) 'minAge': minAge,
      if (maxAge != null) 'maxAge': maxAge,
      if (city != null && city.trim().isNotEmpty) 'city': city.trim(),
      if (onlineOnly == true) 'online': true,
      if (gender != null && gender.trim().isNotEmpty) 'gender': gender.trim(),
      if (membership != null && membership.trim().isNotEmpty)
        'membership': membership.trim(),
      if (interest != null && interest.trim().isNotEmpty)
        'interest': interest.trim(),
    };
    final res = await _dio.safeGet<dynamic>(
      ApiEndpoints.socialDiscovery,
      query: query,
    );
    return _parseFeed(res.data, page: page, limit: limit);
  }

  Future<List<Map<String, dynamic>>> fetchActions({
    String? filter,
    String? scope,
    String? type,
  }) async {
    final res = await _dio.safeGet<dynamic>(
      ApiEndpoints.socialActions,
      query: {
        if (filter != null && filter.isNotEmpty) 'filter': filter,
        if (scope != null && scope.isNotEmpty) 'scope': scope,
        if (type != null && type.isNotEmpty) 'type': type,
      },
    );
    return _parseActionRows(res.data);
  }

  Future<List<SocialDiscoveryUser>> fetchMatches() async {
    final rows = await fetchActions(filter: 'matches');
    return rows
        .map(SocialDiscoveryUser.fromActionRow)
        .where((u) => u.id.isNotEmpty)
        .toList(growable: false);
  }

  Future<SocialDiscoveryActionResult> postAction({
    required String type,
    required String targetId,
    String? message,
  }) async {
    try {
      final res = await _dio.safePost<Map<String, dynamic>>(
        ApiEndpoints.socialActions,
        data: {
          'type': type,
          'targetId': targetId,
          if (message != null && message.isNotEmpty) 'message': message,
        },
      );
      return _parseActionResult(res.data);
    } on ApiException catch (e) {
      return SocialDiscoveryActionResult(
        success: false,
        message: e.message,
        errorCode: e.errorCode,
        statusCode: e.statusCode,
      );
    }
  }

  Future<UserLocationSettings> fetchLocationSettings() async {
    final res = await _dio.safeGet<dynamic>(ApiEndpoints.userLocation);
    final map = _unwrap(res.data);
    return UserLocationSettings.fromJson(map);
  }

  Future<UserLocationSettings> updateLocationSettings(
    Map<String, dynamic> body,
  ) async {
    final res = await _dio.safePost<dynamic>(
      ApiEndpoints.userLocation,
      data: body,
    );
    final map = _unwrap(res.data);
    return UserLocationSettings.fromJson(map);
  }

  SocialDiscoveryFeed _parseFeed(
    dynamic body, {
    required int page,
    required int limit,
  }) {
    final root = _unwrap(body);
    final list = pick(root, [
      'users',
      'candidates',
      'items',
      'results',
      'discovery',
    ]);
    final users = <SocialDiscoveryUser>[];
    if (list is List) {
      for (final e in list) {
        if (e is Map) {
          users.add(
            SocialDiscoveryUser.fromJson(Map<String, dynamic>.from(e)),
          );
        }
      }
    }
    final total = pick(root, ['total']) is num
        ? (pick(root, ['total']) as num).round()
        : users.length;
    final pageNo = pick(root, ['page']) is num
        ? (pick(root, ['page']) as num).round()
        : page;
    final lim = pick(root, ['limit']) is num
        ? (pick(root, ['limit']) as num).round()
        : limit;
    return SocialDiscoveryFeed(
      users: users.where((u) => u.id.isNotEmpty).toList(growable: false),
      total: total,
      page: pageNo,
      limit: lim,
    );
  }

  SocialDiscoveryActionResult _parseActionResult(dynamic body) {
    final root = _unwrap(body);
    final success = root['success'] == true;
    final matched = pick(root, ['matched', 'isMatch', 'match']) == true ||
        pick(asJsonMap(root['data']), ['matched', 'isMatch', 'match']) == true;
    final err = root['error'];
    String? message = pick(root, ['message'])?.toString();
    if ((message == null || message.isEmpty) && err is String) {
      message = err;
    }
    if ((message == null || message.isEmpty) && err is Map) {
      message = pick(asJsonMap(err), ['message', 'error', 'description'])
          ?.toString();
    }
    return SocialDiscoveryActionResult(
      success: success,
      toggled: root['toggled'] == true,
      matched: matched,
      message: message,
      errorCode: pick(asJsonMap(err is Map ? err : null), ['code'])?.toString(),
    );
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
    if (body is! Map) return {};
    final map = Map<String, dynamic>.from(body);
    final data = map['data'];
    if (data is Map) {
      return {...map, ...Map<String, dynamic>.from(data)};
    }
    return map;
  }

  Future<Map<String, dynamic>> fetchSocialProfile({String? userId}) async {
    final res = await _dio.safeGet<dynamic>(
      ApiEndpoints.socialProfile,
      query: {if (userId != null && userId.isNotEmpty) 'userId': userId},
    );
    return _unwrap(res.data);
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
