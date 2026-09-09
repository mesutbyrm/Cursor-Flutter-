import 'package:dio/dio.dart';

import '../../../core/network/api_endpoints.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/network/dio_provider.dart';
import '../../../core/util/json_util.dart';
import '../domain/admin_user_extended_data.dart';
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

  Options _opts([Options? base]) => base ?? Options();

  Future<List<Map<String, dynamic>>> searchUsers(String query) async {
    final q = query.trim();
    if (q.isEmpty) return const [];

    for (final path in [
      ApiEndpoints.adminUsersSearch(q),
      ApiEndpoints.usersSearch(q),
    ]) {
      try {
        final res = await _adminTimeout(
          _dio.safeGet<dynamic>(path, forceRefresh: true, options: _opts()),
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
        options: _opts(),
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
        options: _opts(),
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

  /// Kullanıcı jeton/CFC geçmişi — `GET /api/admin/finance?userId=`.
  Future<List<Map<String, dynamic>>> fetchUserFinanceHistory({
    required String userId,
    int limit = 50,
  }) async {
    try {
      final res = await _adminTimeout(
        _dio.safeGet<dynamic>(
          ApiEndpoints.adminFinance,
          query: {'userId': userId, 'limit': '$limit'},
          forceRefresh: true,
        ),
      );
      final items = _flattenList(
        res.data,
        listKey: 'transactions',
      );
      if (items.isNotEmpty) return items;
      return _flattenList(res.data, listKey: 'history');
    } on ApiException catch (e) {
      if (e.statusCode == 403 || e.statusCode == 404) return const [];
      rethrow;
    }
  }

  /// Sesli oda finans denetimi — `GET /api/admin/voice-room-finance-audit`.
  Future<List<Map<String, dynamic>>> fetchVoiceRoomFinanceAudit({
    int limit = 100,
    String? userId,
  }) async {
    try {
      final res = await _adminTimeout(
        _dio.safeGet<dynamic>(
          ApiEndpoints.adminVoiceRoomFinanceAudit,
          query: {
            'limit': '$limit',
            if (userId != null && userId.isNotEmpty) 'userId': userId,
          },
          forceRefresh: true,
        ),
      );
      final items = _flattenList(res.data, listKey: 'audits');
      if (userId == null || userId.isEmpty) return items;
      return items.where((row) {
        final uid = pick(row, ['userId', 'senderId', 'receiverId'])?.toString();
        if (uid == userId) return true;
        final sender = row['sender'];
        if (sender is Map) {
          final id = pick(asJsonMap(sender), ['id', 'userId'])?.toString();
          if (id == userId) return true;
        }
        final receiver = row['receiver'];
        if (receiver is Map) {
          final id = pick(asJsonMap(receiver), ['id', 'userId'])?.toString();
          if (id == userId) return true;
        }
        return false;
      }).toList(growable: false);
    } on ApiException catch (e) {
      if (e.statusCode == 403 || e.statusCode == 404) return const [];
      rethrow;
    }
  }

  /// Faz 2 — opsiyonel tam kullanıcı kaydı (404 → null).
  Future<Map<String, dynamic>?> tryFetchUserFull(String userId) async {
    return _tryGetMap(ApiEndpoints.adminUserFull(userId));
  }

  Future<List<AdminGiftLedgerRow>> fetchUserGiftLedger(String userId) async {
    final direct = await _tryGetList(ApiEndpoints.adminUserGiftsLedger(userId));
    if (direct.isNotEmpty) return parseGiftLedgerRows(direct);

    final audit = await fetchVoiceRoomFinanceAudit(userId: userId, limit: 80);
    final giftRows = audit
        .where((r) {
          final t = (r['type'] ?? r['eventType'] ?? '').toString().toLowerCase();
          return t.contains('gift') || r['giftId'] != null || r['giftName'] != null;
        })
        .map(AdminGiftLedgerRow.fromMap)
        .toList(growable: false);
    return giftRows;
  }

  Future<List<AdminBroadcastHistoryRow>> fetchUserStreamHistory(
    String userId,
  ) async {
    final direct = await _tryGetList(ApiEndpoints.adminUserStreams(userId));
    if (direct.isNotEmpty) {
      return parseBroadcastHistoryRows(direct, defaultKind: 'stream');
    }
    return const [];
  }

  Future<List<AdminBroadcastHistoryRow>> fetchUserRoomHistory(
    String userId,
  ) async {
    final direct = await _tryGetList(ApiEndpoints.adminUserRooms(userId));
    if (direct.isNotEmpty) {
      return parseBroadcastHistoryRows(direct, defaultKind: 'voice');
    }
    return const [];
  }

  Future<int?> tryFetchUserAdsWatched(String userId) async {
    final data = await _tryGetMap(ApiEndpoints.adminUserAds(userId));
    if (data == null) return null;
    for (final k in ['adsWatched', 'count', 'total', 'watchCount']) {
      final v = data[k];
      if (v is num) return v.toInt();
      if (v is String) {
        final n = int.tryParse(v);
        if (n != null) return n;
      }
    }
    return null;
  }

  Future<List<AdminLiveTellerSummary>> fetchLiveTellers() async {
    try {
      final res = await _adminTimeout(
        _dio.safeGet<dynamic>(
          ApiEndpoints.adminLiveTellers,
          forceRefresh: true,
        ),
      );
      return parseLiveTellerList(res.data);
    } on ApiException catch (e) {
      if (e.statusCode == 403 || e.statusCode == 404) return const [];
      rethrow;
    }
  }

  Future<AdminLiveTellerSummary?> findLiveTellerForUser(String userId) async {
    final list = await fetchLiveTellers();
    for (final t in list) {
      if (t.userId == userId) return t;
      final nested = t.raw['user'];
      if (nested is Map) {
        final id = pick(asJsonMap(nested), ['id', 'userId'])?.toString();
        if (id == userId) return t;
      }
    }
    return null;
  }

  Future<AdminLiveTellerSummary> createLiveTeller({
    required String userId,
    String? displayName,
    String? bio,
    bool isVerified = true,
  }) async {
    final res = await _adminTimeout(
      _dio.safePost<dynamic>(
        ApiEndpoints.adminLiveTellers,
        data: {
          'userId': userId,
          if (displayName != null && displayName.isNotEmpty)
            'displayName': displayName,
          if (bio != null && bio.isNotEmpty) 'bio': bio,
          'isVerified': isVerified ? 'true' : 'false',
        },
      ),
    );
    final map = _unwrapMap(res.data);
    final teller = AdminLiveTellerSummary.fromMap(map);
    if (teller != null) return teller;
    return AdminLiveTellerSummary(
      tellerId: pick(map, ['id', 'tellerId'])?.toString() ?? userId,
      userId: userId,
      displayName: displayName,
      status: 'pending',
      raw: map,
    );
  }

  Future<void> approveLiveTeller(
    String tellerId, {
    String action = 'approve',
    String? note,
  }) async {
    await _adminTimeout(
      _dio.safePost<dynamic>(
        ApiEndpoints.adminLiveTellerApprove(tellerId),
        data: {
          'action': action,
          if (note != null && note.isNotEmpty) 'note': note,
        },
      ),
    );
  }

  Future<void> setWithdrawalLimit({
    required String userId,
    required int limit,
  }) async {
    await _adminTimeout(
      _dio.safePost<dynamic>(
        ApiEndpoints.adminUsersWithdrawalLimit,
        data: {
          'userId': userId,
          'limit': limit.toString(),
        },
      ),
    );
  }

  /// Kurucu — kullanıcı adına sesli oda (404 → ApiException).
  Future<Map<String, dynamic>> createVoiceRoomForUser({
    required String userId,
    required String title,
    String? description,
  }) async {
    final bodies = <Map<String, dynamic>>[
      {
        'userId': userId,
        'title': title,
        if (description != null && description.isNotEmpty)
          'description': description,
      },
      {
        'ownerUserId': userId,
        'name': title,
        if (description != null && description.isNotEmpty)
          'description': description,
      },
    ];

    ApiException? last;
    for (final body in bodies) {
      try {
        final res = await _adminTimeout(
          _dio.safePost<dynamic>(
            ApiEndpoints.adminChatRoomsCreateForUser,
            data: body,
          ),
        );
        return _unwrapMap(res.data);
      } on ApiException catch (e) {
        last = e;
        if (e.statusCode == 400 || e.statusCode == 422) continue;
        if (e.statusCode == 404 || e.statusCode == 405) break;
        rethrow;
      }
    }
    throw last ??
        const ApiException(
          'Adına oda açma uç noktası henüz üretimde yok.',
          statusCode: 404,
        );
  }

  Future<List<Map<String, dynamic>>> fetchPendingPaymentsForUser(
    String userId,
  ) async {
    final merged = <String, Map<String, dynamic>>{};

    Future<void> ingest(String path) async {
      try {
        final res = await _adminTimeout(
          _dio.safeGet<dynamic>(
            path,
            query: {'status': 'pending', 'limit': '50', 'userId': userId},
            forceRefresh: true,
          ),
        );
        for (final row in _flattenList(res.data, listKey: 'requests')) {
          final id = row['id']?.toString();
          if (id != null) merged[id] = row;
        }
      } on ApiException catch (e) {
        if (e.statusCode != 403 && e.statusCode != 404) rethrow;
      }
    }

    await Future.wait([
      ingest(ApiEndpoints.adminPaymentRequests),
      ingest(ApiEndpoints.adminCfcPaymentRequests),
    ]);

    return merged.values.where((row) {
      final uid = pick(row, ['userId', 'uid', 'targetUserId'])?.toString();
      if (uid == userId) return true;
      final user = row['user'];
      if (user is Map) {
        final id = pick(asJsonMap(user), ['id', 'userId'])?.toString();
        if (id == userId) return true;
      }
      return false;
    }).toList(growable: false);
  }

  Future<Map<String, dynamic>?> _tryGetMap(String path) async {
    try {
      final res = await _adminTimeout(
        _dio.safeGet<dynamic>(path, forceRefresh: true),
      );
      final map = _unwrapMap(res.data);
      return map.isEmpty ? null : map;
    } on ApiException catch (e) {
      if (e.statusCode == 403 || e.statusCode == 404) return null;
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> _tryGetList(String path) async {
    try {
      final res = await _adminTimeout(
        _dio.safeGet<dynamic>(path, forceRefresh: true),
      );
      return _flattenList(res.data);
    } on ApiException catch (e) {
      if (e.statusCode == 403 || e.statusCode == 404) return const [];
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
