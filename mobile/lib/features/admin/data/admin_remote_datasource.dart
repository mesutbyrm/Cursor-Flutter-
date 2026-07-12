import 'package:dio/dio.dart';

import '../../../core/network/api_endpoints.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/network/dio_provider.dart';
import '../../../core/util/json_util.dart';
import '../domain/admin_user_util.dart';

const _adminCallTimeout = Duration(seconds: 12);

Future<T> _adminTimeout<T>(Future<T> future) {
  return future.timeout(
    _adminCallTimeout,
    onTimeout: () => throw ApiException(
      'İstek zaman aşımına uğradı. Lütfen tekrar deneyin.',
      statusCode: 408,
    ),
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
        final items = normalizeAdminUserList(_flattenList(res.data));
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
    return normalizeAdminUserMap(_unwrapMap(res.data));
  }

  Future<Map<String, dynamic>> updateUser(
    String userId,
    Map<String, dynamic> patch,
  ) async {
    final res = await _adminTimeout(
      _dio.safePatch<dynamic>(
        ApiEndpoints.adminUser(userId),
        data: patch,
      ),
    );
    return normalizeAdminUserMap(_unwrapMap(res.data));
  }

  Future<void> adjustCredits({
    required String userId,
    required String type,
    required int amount,
    required bool add,
    String? reason,
  }) async {
    final uid = userId.trim();
    if (uid.isEmpty) {
      throw const ApiException('Kullanıcı kimliği bulunamadı.');
    }
    if (amount < 1) {
      throw const ApiException('Geçerli bir miktar girin.');
    }

    final note = reason?.trim();
    final action = add ? 'add' : 'subtract';
    final types = type == 'jeton'
        ? <String>['jeton', 'coins', 'coin']
        : <String>['cfc', type];

    ApiException? lastError;
    for (final creditType in types) {
      final bodies = <Map<String, dynamic>>[
        {
          'userId': uid,
          'type': creditType,
          'amount': amount,
          'action': action,
          if (note != null && note.isNotEmpty) 'reason': note,
          if (note != null && note.isNotEmpty) 'note': note,
        },
        {
          'userId': uid,
          'type': creditType,
          'amount': amount,
          'operation': action,
          if (note != null && note.isNotEmpty) 'reason': note,
        },
        {
          'userId': uid,
          'creditType': creditType,
          'amount': amount,
          'action': action,
          if (note != null && note.isNotEmpty) 'note': note,
        },
      ];

      for (final body in bodies) {
        try {
          await _adminTimeout(
            _dio.safePatch<dynamic>(
              ApiEndpoints.adminUsersCredits,
              data: body,
            ),
          );
          return;
        } on ApiException catch (e) {
          lastError = e;
          if (e.statusCode == 404 || e.statusCode == 405) break;
          if (e.statusCode == 400 || e.statusCode == 422) continue;
          if (e.statusCode == 401 || e.statusCode == 403) rethrow;
        }

        try {
          await _adminTimeout(
            _dio.safePost<dynamic>(
              ApiEndpoints.adminCredits,
              data: body,
            ),
          );
          return;
        } on ApiException catch (e) {
          lastError = e;
          if (e.statusCode == 404 || e.statusCode == 405) continue;
          if (e.statusCode == 400 || e.statusCode == 422) continue;
          if (e.statusCode == 401 || e.statusCode == 403) rethrow;
        }
      }
    }

    throw lastError ?? const ApiException('Jeton/CFC güncellenemedi.');
  }

  Future<void> grantMembership({
    required String userId,
    required String tier,
    required String duration,
    String? reason,
  }) async {
    final uid = userId.trim();
    if (uid.isEmpty) {
      throw const ApiException('Kullanıcı kimliği bulunamadı.');
    }

    final note = reason?.trim();
    final days = switch (duration) {
      'daily' => 1,
      'weekly' => 7,
      _ => 30,
    };

    final bodies = <Map<String, dynamic>>[
      {
        'userId': uid,
        'tier': tier,
        'membership': tier,
        'duration': duration,
        'period': duration,
        'days': days,
        if (note != null && note.isNotEmpty) 'reason': note,
        if (note != null && note.isNotEmpty) 'note': note,
      },
      {
        'userId': uid,
        'membershipTier': tier,
        'membership': tier,
        'durationDays': days,
        if (note != null && note.isNotEmpty) 'note': note,
      },
    ];

    ApiException? lastError;
    for (final body in bodies) {
      try {
        await _adminTimeout(
          _dio.safePatch<dynamic>(
            ApiEndpoints.adminUsersGrantMembership,
            data: body,
          ),
        );
        return;
      } on ApiException catch (e) {
        lastError = e;
        if (e.statusCode == 400 || e.statusCode == 422) continue;
        if (e.statusCode == 401 || e.statusCode == 403) rethrow;
        if (e.statusCode != 404 && e.statusCode != 405) rethrow;
      }
    }

    // Son çare — kullanıcı kaydına üyelik yaz.
    try {
      await updateUser(uid, {
        'membership': tier,
        'membershipTier': tier,
        'membershipExpiresAt': DateTime.now()
            .add(Duration(days: days))
            .toUtc()
            .toIso8601String(),
        if (note != null && note.isNotEmpty) 'adminNote': note,
      });
      return;
    } on ApiException catch (e) {
      lastError = e;
    }

    throw lastError ?? const ApiException('Üyelik verilemedi.');
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
