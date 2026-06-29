import 'package:dio/dio.dart';

import '../../../core/network/api_endpoints.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/network/dio_provider.dart';
import '../../../core/util/json_util.dart';

const _adminCallTimeout = Duration(seconds: 8);

Future<T> _adminTimeout<T>(Future<T> future) {
  return future.timeout(
    _adminCallTimeout,
    onTimeout: () => throw ApiException('timeout', statusCode: 408),
  );
}

/// canlifal.com admin API — web paneli ile aynı uç noktalar.
class AdminRemoteDataSource {
  AdminRemoteDataSource(this._dio);

  final Dio _dio;

  Future<List<Map<String, dynamic>>> searchUsers(String query) async {
    final q = query.trim();
    if (q.isEmpty) return const [];

    for (final path in [
      ApiEndpoints.adminUsersSearch(q),
      ApiEndpoints.usersSearch(q),
    ]) {
      try {
        final res = await _adminTimeout(
          _dio.safeGet<dynamic>(path, forceRefresh: true),
        );
        final items = _flattenList(res.data);
        if (items.isNotEmpty) return items;
      } on ApiException catch (e) {
        if (e.statusCode == 404) continue;
        if (e.statusCode == 403 && path.contains('/admin/')) continue;
        rethrow;
      }
    }
    return const [];
  }

  Future<Map<String, dynamic>> fetchUser(String userId) async {
    final res = await _adminTimeout(
      _dio.safeGet<dynamic>(
        ApiEndpoints.adminUser(userId),
        forceRefresh: true,
      ),
    );
    return _unwrapMap(res.data);
  }

  Future<Map<String, dynamic>> updateUser(
    String userId,
    Map<String, dynamic> patch,
  ) async {
    final res = await _dio.safePatch<dynamic>(
      ApiEndpoints.adminUser(userId),
      data: patch,
    );
    return _unwrapMap(res.data);
  }

  Future<void> adjustCredits({
    required String userId,
    required String type,
    required int amount,
    required bool add,
    String? reason,
  }) async {
    final body = {
      'userId': userId,
      'type': type,
      'amount': amount.abs(),
      'action': add ? 'add' : 'subtract',
      if (reason != null && reason.trim().isNotEmpty) 'reason': reason.trim(),
      if (reason != null && reason.trim().isNotEmpty) 'note': reason.trim(),
    };

    try {
      await _dio.safePatch<dynamic>(
        ApiEndpoints.adminUsersCredits,
        data: body,
      );
      return;
    } on ApiException catch (e) {
      if (e.statusCode != 404 && e.statusCode != 405) rethrow;
    }

    await _dio.safePost<dynamic>(
      ApiEndpoints.adminCredits,
      data: body,
    );
  }

  Future<void> grantMembership({
    required String userId,
    required String tier,
    required String duration,
    String? reason,
  }) async {
    await _dio.safePatch<dynamic>(
      ApiEndpoints.adminUsersGrantMembership,
      data: {
        'userId': userId,
        'tier': tier,
        'membership': tier,
        'duration': duration,
        'period': duration,
        if (reason != null && reason.trim().isNotEmpty) 'reason': reason.trim(),
        if (reason != null && reason.trim().isNotEmpty) 'note': reason.trim(),
      },
    );
  }

  Future<Map<String, dynamic>> fetchDashboardStats() async {
    final merged = <String, dynamic>{};

    Future<void> merge(String path, Map<String, String>? query) async {
      try {
        final res = await _adminTimeout(
          _dio.safeGet<dynamic>(
            path,
            query: query,
            forceRefresh: true,
          ),
        );
        if (res.data is Map) {
          merged.addAll(_unwrapMap(res.data));
        }
      } on ApiException catch (e) {
        if (e.statusCode != 403 && e.statusCode != 404) rethrow;
      }
    }

    await Future.wait([
      merge(ApiEndpoints.adminUsersStats, null),
      merge(ApiEndpoints.adminFinance, null),
      merge(ApiEndpoints.adminWithdrawals, {'status': 'pending', 'limit': '50'}),
    ]);

    return merged;
  }

  Future<List<Map<String, dynamic>>> fetchActivities({int limit = 100}) async {
    for (final path in [ApiEndpoints.adminActivityFeed, ApiEndpoints.activities]) {
      try {
        final res = await _adminTimeout(
          _dio.safeGet<dynamic>(
            path,
            query: {'limit': '$limit'},
            forceRefresh: true,
          ),
        );
        final items = _flattenList(res.data, listKey: 'activities');
        if (items.isNotEmpty) return items;
      } on ApiException catch (e) {
        if (e.statusCode == 403 || e.statusCode == 404) continue;
        rethrow;
      }
    }
    return const [];
  }

  Future<Map<String, dynamic>> fetchLeaderboards({String period = 'today'}) async {
    try {
      final res = await _adminTimeout(
        _dio.safeGet<dynamic>(
          ApiEndpoints.leaderboards,
          query: {'period': period},
          forceRefresh: true,
        ),
      );
      if (res.data is Map) return asJsonMap(res.data);
    } on ApiException catch (e) {
      if (e.statusCode != 403 && e.statusCode != 404 && e.statusCode != 408) {
        rethrow;
      }
    }
    return const {};
  }

  Future<int> pendingWithdrawalsCount() async {
    try {
      final res = await _adminTimeout(
        _dio.safeGet<dynamic>(
          ApiEndpoints.adminWithdrawals,
          query: {'status': 'pending', 'limit': '50'},
          forceRefresh: true,
        ),
      );
      return _flattenList(res.data).length;
    } on ApiException catch (e) {
      if (e.statusCode == 403 || e.statusCode == 404 || e.statusCode == 408) {
        return 0;
      }
      rethrow;
    }
  }

  Map<String, dynamic> _unwrapMap(dynamic data) {
    if (data is Map && data['success'] == true && data['data'] is Map) {
      return asJsonMap(data['data']);
    }
    if (data is Map) return asJsonMap(data);
    return {};
  }

  List<Map<String, dynamic>> _flattenList(
    dynamic data, {
    String listKey = 'items',
  }) {
    if (data is List) {
      return data.map((e) => asJsonMap(e)).toList();
    }
    if (data is! Map) return const [];

    final map = asJsonMap(data);
    for (final key in [
      listKey,
      'items',
      'users',
      'requests',
      'activities',
      'withdrawals',
      'data',
    ]) {
      final val = map[key];
      if (val is List) {
        return val.map((e) => asJsonMap(e)).toList();
      }
      if (val is Map) {
        final nested = _flattenList(val, listKey: listKey);
        if (nested.isNotEmpty) return nested;
      }
    }

    if (map['success'] == true && map['data'] != null) {
      return _flattenList(map['data'], listKey: listKey);
    }

    return const [];
  }
}
