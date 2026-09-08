import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/network/api_endpoints.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/network/dio_provider.dart';
import '../../../core/site_animation/data/site_animation_catalog_datasource.dart';
import '../../../core/util/json_util.dart';
import '../domain/admin_site_animation.dart';
import 'admin_site_animation_seed_catalog.dart';

const _prefsKey = 'admin_site_animations_local_v1';
const _defaultsKey = 'admin_site_animation_defaults_v1';
const _assignmentsKey = 'admin_site_animation_assignments_v1';

/// Site animasyon admin API — üretim uçları + yerel seed fallback.
class AdminSiteAnimationRemoteDataSource {
  AdminSiteAnimationRemoteDataSource(this._dio);

  final Dio _dio;

  Future<List<AdminSiteAnimation>> listAnimations() async {
    try {
      final res = await _dio.safeGet<dynamic>(
        ApiEndpoints.adminSiteAnimations,
        forceRefresh: true,
        options: Options(extra: const {'noCache': true}),
      );
      final raw = _unwrapList(res.data);
      if (raw.isNotEmpty) {
        return raw
            .map((e) => AdminSiteAnimation.fromJson(asJsonMap(e)))
            .toList();
      }
    } on ApiException catch (e) {
      if (e.statusCode != 404 && e.statusCode != 403) rethrow;
    }
    return _loadLocalOrSeed();
  }

  Future<AdminSiteAnimationStats> fetchStats() async {
    try {
      final res = await _dio.safeGet<dynamic>(
        ApiEndpoints.adminSiteAnimationsStats,
        forceRefresh: true,
      );
      final map = asJsonMap(_unwrapMap(res.data));
      if (map.isNotEmpty) {
        return AdminSiteAnimationStats.fromJson(map);
      }
    } on ApiException catch (e) {
      if (e.statusCode != 404 && e.statusCode != 403) rethrow;
    }
    final items = await listAnimations();
    return AdminSiteAnimationStats.fromList(items);
  }

  Future<AdminSiteAnimation> create(Map<String, dynamic> body) async {
    try {
      final res = await _dio.safePost<dynamic>(
        ApiEndpoints.adminSiteAnimations,
        data: body,
      );
      return AdminSiteAnimation.fromJson(asJsonMap(_unwrapMap(res.data)));
    } on ApiException catch (e) {
      if (e.statusCode != 404 && e.statusCode != 403) rethrow;
    }
    final item = AdminSiteAnimation.fromJson(body);
    final items = await _loadLocalOrSeed();
    final next = [...items, item.copyWith(isActive: true)];
    await _saveLocal(next);
    await _syncRuntimeCatalog();
    return item;
  }

  Future<AdminSiteAnimation> update(String id, Map<String, dynamic> patch) async {
    try {
      final res = await _dio.safePatch<dynamic>(
        ApiEndpoints.adminSiteAnimation(id),
        data: patch,
      );
      return AdminSiteAnimation.fromJson(asJsonMap(_unwrapMap(res.data)));
    } on ApiException catch (e) {
      if (e.statusCode != 404 && e.statusCode != 403) rethrow;
    }
    final items = await _loadLocalOrSeed();
    final idx = items.indexWhere((a) => a.id == id);
    if (idx < 0) throw ApiException('Animasyon bulunamadı.', statusCode: 404);
    final merged = AdminSiteAnimation.fromJson({
      ...items[idx].toJson(),
      ...patch,
      'id': id,
    });
    final next = [...items]..[idx] = merged;
    await _saveLocal(next);
    await _syncRuntimeCatalog();
    return merged;
  }

  Future<void> setActive(String id, bool active) =>
      update(id, {'isActive': active});

  Future<Map<AdminSiteAnimationMembership, String>> fetchDefaults() async {
    try {
      final res = await _dio.safeGet<dynamic>(
        ApiEndpoints.adminSiteAnimationDefaults,
        forceRefresh: true,
      );
      final map = asJsonMap(_unwrapMap(res.data));
      if (map.isNotEmpty) return _parseDefaults(map);
    } on ApiException catch (e) {
      if (e.statusCode != 404 && e.statusCode != 403) rethrow;
    }
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_defaultsKey);
    if (raw != null) {
      return _parseDefaults(jsonDecode(raw) as Map<String, dynamic>);
    }
    return AdminSiteAnimationSeedCatalog.defaultEntranceIds();
  }

  Future<void> saveDefaults(
    Map<AdminSiteAnimationMembership, String> defaults,
  ) async {
    final body = {
      for (final e in defaults.entries) e.key.name: e.value,
    };
    try {
      await _dio.safePut<dynamic>(
        ApiEndpoints.adminSiteAnimationDefaults,
        data: body,
      );
      return;
    } on ApiException catch (e) {
      if (e.statusCode != 404 && e.statusCode != 403) rethrow;
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_defaultsKey, jsonEncode(body));
    await _syncRuntimeCatalog();
  }

  Future<Map<AdminSiteAnimationSlot, String?>> fetchUserAssignments(
    String userId,
  ) async {
    try {
      final res = await _dio.safeGet<dynamic>(
        ApiEndpoints.adminSiteAnimationUser(userId),
        forceRefresh: true,
      );
      final map = asJsonMap(_unwrapMap(res.data));
      return _parseAssignments(map);
    } on ApiException catch (e) {
      if (e.statusCode != 404 && e.statusCode != 403) rethrow;
    }
    final prefs = await SharedPreferences.getInstance();
    final all = prefs.getString(_assignmentsKey);
    if (all == null) return {};
    final root = jsonDecode(all) as Map<String, dynamic>;
    final user = asJsonMap(root[userId]);
    return _parseAssignments(user);
  }

  Future<void> assignAnimation({
    required String userId,
    required AdminSiteAnimationSlot slot,
    required String? animationId,
    DateTime? expiresAt,
  }) async {
    try {
      await _dio.safePost<dynamic>(
        ApiEndpoints.adminSiteAnimationAssign,
        data: {
          'userId': userId,
          'slot': slot.name,
          'animationId': animationId,
          if (expiresAt != null) 'expiresAt': expiresAt.toIso8601String(),
        },
      );
      return;
    } on ApiException catch (e) {
      if (e.statusCode != 404 && e.statusCode != 403) rethrow;
    }
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_assignmentsKey);
    final root = raw != null
        ? Map<String, dynamic>.from(jsonDecode(raw) as Map)
        : <String, dynamic>{};
    final user = Map<String, dynamic>.from(asJsonMap(root[userId]));
    user[slot.name] = animationId;
    if (expiresAt != null) {
      user['${slot.name}_expiresAt'] = expiresAt.toIso8601String();
    }
    root[userId] = user;
    await prefs.setString(_assignmentsKey, jsonEncode(root));
    await _syncRuntimeCatalog();
  }

  Future<void> bulkAssign({
    required List<String> userIds,
    required AdminSiteAnimationSlot slot,
    required String animationId,
    DateTime? expiresAt,
  }) async {
    try {
      await _dio.safePost<dynamic>(
        ApiEndpoints.adminSiteAnimationBulkAssign,
        data: {
          'userIds': userIds,
          'slot': slot.name,
          'animationId': animationId,
          if (expiresAt != null) 'expiresAt': expiresAt.toIso8601String(),
        },
      );
      return;
    } on ApiException catch (e) {
      if (e.statusCode != 404 && e.statusCode != 403) rethrow;
    }
    for (final uid in userIds) {
      await assignAnimation(
        userId: uid,
        slot: slot,
        animationId: animationId,
        expiresAt: expiresAt,
      );
    }
  }

  Future<List<AdminSiteAnimation>> _loadLocalOrSeed() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_prefsKey);
    if (raw != null) {
      final list = jsonDecode(raw) as List<dynamic>;
      return list
          .map((e) => AdminSiteAnimation.fromJson(asJsonMap(e)))
          .toList();
    }
    return AdminSiteAnimationSeedCatalog.all();
  }

  Future<void> _saveLocal(List<AdminSiteAnimation> items) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _prefsKey,
      jsonEncode(items.map((e) => e.toJson()).toList()),
    );
  }

  Future<void> _syncRuntimeCatalog() async {
    await SiteAnimationCatalogDataSource(_dio).syncFromAdminLocal();
  }

  Map<AdminSiteAnimationMembership, String> _parseDefaults(
    Map<String, dynamic> map,
  ) {
    final out = <AdminSiteAnimationMembership, String>{};
    for (final e in map.entries) {
      final tier = AdminSiteAnimationMembership.parse(e.key);
      if (tier == null || tier == AdminSiteAnimationMembership.all) continue;
      final id = e.value?.toString();
      if (id != null && id.isNotEmpty) out[tier] = id;
    }
    return out;
  }

  Map<AdminSiteAnimationSlot, String?> _parseAssignments(
    Map<String, dynamic> map,
  ) {
    final out = <AdminSiteAnimationSlot, String?>{};
    for (final slot in AdminSiteAnimationSlot.values) {
      final v = map[slot.name]?.toString();
      out[slot] = v;
    }
    return out;
  }

  List<dynamic> _unwrapList(dynamic data) {
    if (data is List) return data;
    if (data is Map) {
      final m = asJsonMap(data);
      return (m['animations'] ?? m['items'] ?? m['data']) as List? ?? const [];
    }
    return const [];
  }

  Map<String, dynamic> _unwrapMap(dynamic data) {
    if (data is Map) {
      final m = asJsonMap(data);
      if (m['animation'] is Map) return asJsonMap(m['animation']);
      if (m['data'] is Map) return asJsonMap(m['data']);
      return m;
    }
    return const {};
  }
}
