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
const _exitDefaultsKey = 'admin_site_animation_exit_defaults_v1';
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

  /// `POST` — gövde [AdminSiteAnimation.toApiJson] biçiminde olmalı.
  /// Hata yerelde «kaydedildi» gibi gösterilmez (önceden 403/404 yerel
  /// kopyaya yazılıp başarı sanılıyordu).
  Future<AdminSiteAnimation> create(Map<String, dynamic> body) async {
    final res = await _dio.safePost<dynamic>(
      ApiEndpoints.adminSiteAnimations,
      data: body,
    );
    final created = AdminSiteAnimation.fromJson(asJsonMap(_unwrapMap(res.data)));
    await _syncRuntimeCatalog();
    return created;
  }

  Future<AdminSiteAnimation> update(
    String id,
    Map<String, dynamic> patch,
  ) async {
    final res = await _dio.safePatch<dynamic>(
      ApiEndpoints.adminSiteAnimation(id),
      data: patch,
    );
    final updated = AdminSiteAnimation.fromJson(asJsonMap(_unwrapMap(res.data)));
    await _syncRuntimeCatalog();
    return updated;
  }

  Future<void> setActive(String id, bool active) =>
      update(id, {'status': active ? 'active' : 'inactive'});

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

  /// Backend `MEMBERSHIP_TIERS` + `admin`; `host`/`all` sunucuda yok.
  static String? _backendTier(AdminSiteAnimationMembership m) => switch (m) {
    AdminSiteAnimationMembership.normal => 'basic',
    AdminSiteAnimationMembership.host ||
    AdminSiteAnimationMembership.all => null,
    _ => m.name,
  };

  Future<void> saveDefaults(
    Map<AdminSiteAnimationMembership, String> defaults,
  ) async {
    // Backend: `POST {membershipTier, category, animationId}` (seviye başına
    // upsert). Hata yerel kayda düşürülmez — önceden bir kısmı sunucuya bir
    // kısmı telefona yazılıp başarı gibi görünüyordu.
    _ensureServerIds(defaults.values);
    for (final e in defaults.entries) {
      final tier = _backendTier(e.key);
      if (tier == null) continue;
      await _dio.safePost<dynamic>(
        ApiEndpoints.adminSiteAnimationDefaults,
        data: {
          'membershipTier': tier,
          'category': 'entrance',
          'animationId': e.value,
        },
      );
    }
    await _syncRuntimeCatalog();
  }

  Future<Map<AdminSiteAnimationMembership, String>> fetchExitDefaults() async {
    try {
      final res = await _dio.safeGet<dynamic>(
        ApiEndpoints.adminSiteAnimationExitDefaults,
        forceRefresh: true,
      );
      final map = asJsonMap(_unwrapMap(res.data));
      if (map.isNotEmpty) return _parseDefaults(map);
    } on ApiException catch (e) {
      if (e.statusCode != 404 && e.statusCode != 403) rethrow;
    }
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_exitDefaultsKey);
    if (raw != null) {
      return _parseDefaults(jsonDecode(raw) as Map<String, dynamic>);
    }
    return AdminSiteAnimationSeedCatalog.defaultExitIds();
  }

  Future<void> saveExitDefaults(
    Map<AdminSiteAnimationMembership, String> defaults,
  ) async {
    // Backend: `POST {membershipTier, category, animationId}` (seviye başına
    // upsert). Hata yerel kayda düşürülmez — önceden bir kısmı sunucuya bir
    // kısmı telefona yazılıp başarı gibi görünüyordu.
    _ensureServerIds(defaults.values);
    for (final e in defaults.entries) {
      final tier = _backendTier(e.key);
      if (tier == null) continue;
      await _dio.safePost<dynamic>(
        ApiEndpoints.adminSiteAnimationExitDefaults,
        data: {
          'membershipTier': tier,
          'category': 'exit',
          'animationId': e.value,
        },
      );
    }
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

  /// Sunucu kategorisi (atama slotu → `Animation.category`).
  static String slotCategory(AdminSiteAnimationSlot slot) => switch (slot) {
        AdminSiteAnimationSlot.profileFrame => 'profile_frame',
        AdminSiteAnimationSlot.mic => 'microphone',
        _ => slot.name,
      };

  /// Web paneliyle aynı sözleşme: `{animationId, target:{type:'user',userId},
  /// duration, endDate}`; kaldırma `DELETE ?userId=&category=`. Önceden
  /// `userId`/`slot`/`expiresAt` gönderildiği için atama hep 400 dönüyordu.
  Future<void> assignAnimation({
    required String userId,
    required AdminSiteAnimationSlot slot,
    required String? animationId,
    DateTime? expiresAt,
  }) async {
    if (animationId == null || animationId.isEmpty) {
      await _dio.safeDelete<dynamic>(
        ApiEndpoints.adminAnimationAssignments,
        query: {'userId': userId, 'category': slotCategory(slot)},
      );
      await _syncRuntimeCatalog();
      return;
    }
    await _dio.safePost<dynamic>(
      ApiEndpoints.adminSiteAnimationAssign,
      data: {
        'animationId': animationId,
        'target': {'type': 'user', 'userId': userId},
        'duration': expiresAt != null ? 'custom' : 'permanent',
        if (expiresAt != null) 'endDate': expiresAt.toUtc().toIso8601String(),
      },
    );
    await _syncRuntimeCatalog();
  }

  Future<void> bulkAssign({
    required List<String> userIds,
    required AdminSiteAnimationSlot slot,
    required String animationId,
    DateTime? expiresAt,
  }) async {
    // Süre `duration`/`endDate` ile (önceden `expiresAt` okunmadığı için
    // süreli atamalar kalıcı oluyordu).
    await _dio.safePost<dynamic>(
      ApiEndpoints.adminSiteAnimationBulkAssign,
      data: {
        'userIds': userIds,
        'animationId': animationId,
        'duration': expiresAt != null ? 'custom' : 'permanent',
        if (expiresAt != null) 'endDate': expiresAt.toUtc().toIso8601String(),
      },
    );
    await _syncRuntimeCatalog();
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

  /// Yerel örnek katalog kimlikleri sunucuda yoktur (sunucu 404 / 500 verir).
  void _ensureServerIds(Iterable<String> ids) {
    final local = AdminSiteAnimationSeedCatalog.all().map((a) => a.id).toSet();
    if (ids.any(local.contains)) {
      throw const ApiException(
        'Seçilen animasyonlardan bazıları yalnız örnek katalogda; önce '
        'Animasyon Kütüphanesi\'ne ekleyip sunucudaki animasyonu seçin.',
        statusCode: 400,
      );
    }
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
