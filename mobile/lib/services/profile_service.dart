import 'package:dio/dio.dart';

import '../core/api_response.dart';
import '../core/network/api_endpoints.dart';
import '../core/network/api_exception.dart';
import '../core/network/dio_provider.dart';
import '../core/util/json_util.dart';
import 'service_utils.dart';

/// Profil / kullanıcı API — kılavuz §9.2 `UserRepository`.
class ProfileService {
  ProfileService({required Dio Function() resolveAuthedDio})
      : _resolveAuthedDio = resolveAuthedDio;

  final Dio Function() _resolveAuthedDio;
  Dio get _dio => _resolveAuthedDio();

  /// `GET /api/me`
  Future<Map<String, dynamic>> getMe() async {
    final res = await _dio.safeGet<dynamic>(ApiEndpoints.me);
    final map = ServiceUtils.unwrapMap(res.data) ?? asJsonMap(res.data);
    final user = map['user'] ?? map;
    return user is Map ? Map<String, dynamic>.from(user) : map;
  }

  /// `PATCH /api/me` veya kılavuz yedek `PATCH /api/user/profile`.
  Future<Map<String, dynamic>> updateProfile(Map<String, dynamic> data) async {
    try {
      final res = await _dio.safePatch<dynamic>(ApiEndpoints.me, data: data);
      return ServiceUtils.unwrapMap(res.data) ?? asJsonMap(res.data);
    } on ApiException catch (e) {
      if (e.statusCode != 404 && e.statusCode != 405) rethrow;
      final res = await _dio.safePatch<dynamic>(
        ApiEndpoints.userSiteProfile,
        data: data,
      );
      return ServiceUtils.unwrapMap(res.data) ?? asJsonMap(res.data);
    }
  }

  /// `GET /api/users/{userId}`
  Future<Map<String, dynamic>> getUser(String userId) async {
    final res = await _dio.safeGet<dynamic>(ApiEndpoints.userProfile(userId));
    final map = ServiceUtils.unwrapMap(res.data) ?? asJsonMap(res.data);
    final user = map['user'] ?? map['profile'] ?? map;
    return user is Map ? Map<String, dynamic>.from(user) : map;
  }

  /// `POST /api/user/{userId}/follow` (+ `/api/users/{id}/follow` yedek).
  Future<void> follow(String userId) async {
    Object? lastError;
    for (final path in [
      ApiEndpoints.userFollow(userId),
      ApiEndpoints.follow(userId),
    ]) {
      try {
        await _dio.safePost<dynamic>(path);
        return;
      } catch (e) {
        lastError = e;
      }
    }
    throw ApiException.userMessage(lastError ?? 'Takip edilemedi');
  }

  /// `DELETE /api/user/{userId}/follow`
  Future<void> unfollow(String userId) async {
    try {
      await _dio.safeDelete<dynamic>(ApiEndpoints.userFollow(userId));
      return;
    } on ApiException catch (e) {
      if (e.statusCode != 404 && e.statusCode != 405) rethrow;
    }
    await _dio.safeDelete<dynamic>(ApiEndpoints.follow(userId));
  }

  /// `GET /api/user/followers`
  Future<List<Map<String, dynamic>>> getFollowers({
    int page = 1,
    int limit = 20,
  }) async {
    final res = await _dio.safeGet<dynamic>(
      ApiEndpoints.userFollowers,
      query: apiPageQuery(page: page, limit: limit),
    );
    return ServiceUtils.extractList(
      res.data,
      keys: const ['followers', 'users', 'items', 'data'],
    );
  }

  /// `GET /api/user/following`
  Future<List<Map<String, dynamic>>> getFollowing({
    int page = 1,
    int limit = 20,
  }) async {
    final res = await _dio.safeGet<dynamic>(
      ApiEndpoints.userFollowing,
      query: apiPageQuery(page: page, limit: limit),
    );
    return ServiceUtils.extractList(
      res.data,
      keys: const ['following', 'users', 'items', 'data'],
    );
  }

  /// `GET /api/users/search?q=query`
  Future<List<Map<String, dynamic>>> searchUsers(String query) async {
    final q = query.trim();
    if (q.length < 2) return const [];
    final res = await _dio.safeGet<dynamic>(ApiEndpoints.usersSearch(q));
    return ServiceUtils.extractList(
      res.data,
      keys: const ['users', 'results', 'items', 'data'],
    );
  }

  /// `GET /api/users/online`
  Future<List<Map<String, dynamic>>> getOnlineUsers() async {
    final res = await _dio.safeGet<dynamic>(ApiEndpoints.usersOnline);
    return ServiceUtils.extractList(
      res.data,
      keys: const ['users', 'online', 'items', 'data'],
    );
  }

  /// `GET /api/user/achievements`
  Future<List<Map<String, dynamic>>> getAchievements() async {
    final res = await _dio.safeGet<dynamic>(ApiEndpoints.userAchievements);
    return ServiceUtils.extractList(
      res.data,
      keys: const ['achievements', 'items', 'data'],
    );
  }

  /// `GET /api/user/xp`
  Future<Map<String, dynamic>> getXP() async {
    final res = await _dio.safeGet<dynamic>(ApiEndpoints.userXp);
    return ServiceUtils.unwrapMap(res.data) ?? asJsonMap(res.data);
  }

  /// `GET /api/user/credits`
  Future<Map<String, dynamic>> getCredits() async {
    final res = await _dio.safeGet<dynamic>(ApiEndpoints.userCredits);
    return ServiceUtils.unwrapMap(res.data) ?? asJsonMap(res.data);
  }
}
