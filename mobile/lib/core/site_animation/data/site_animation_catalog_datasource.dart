import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/network/api_endpoints.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/network/dio_provider.dart';
import '../../../core/util/json_util.dart';
import '../../../features/admin/data/admin_site_animation_seed_catalog.dart';
import '../../../features/admin/domain/admin_site_animation.dart';
import '../domain/site_animation_catalog_entry.dart';
import '../domain/site_animation_layout.dart';
import '../domain/site_animation_slot.dart';
import '../domain/site_animation_tier.dart';

const siteAnimationCatalogPrefsKey = 'site_animation_catalog_v1';
const _adminCatalogKey = 'admin_site_animations_local_v1';
const _adminDefaultsKey = 'admin_site_animation_defaults_v1';
const _adminExitDefaultsKey = 'admin_site_animation_exit_defaults_v1';
const _adminAssignmentsKey = 'admin_site_animation_assignments_v1';

/// Aktif site animasyon kataloğu — API, admin prefs veya seed.
class SiteAnimationCatalogDataSource {
  SiteAnimationCatalogDataSource(this._dio);

  final Dio _dio;

  Future<SiteAnimationCatalogSnapshot> load({bool forceRefresh = false}) async {
    try {
      final res = await _dio.safeGet<dynamic>(
        ApiEndpoints.siteAnimationsActive,
        forceRefresh: forceRefresh,
        options: Options(extra: const {'noCache': true}),
      );
      final snapshot = _parseApiPayload(res.data);
      if (snapshot.animations.isNotEmpty) {
        await _persist(snapshot);
        return snapshot;
      }
    } on ApiException catch (e) {
      if (e.statusCode != 404 && e.statusCode != 403) rethrow;
    }

    final prefs = await SharedPreferences.getInstance();
    final cached = prefs.getString(siteAnimationCatalogPrefsKey);
    if (cached != null) {
      return _parseCached(jsonDecode(cached) as Map<String, dynamic>);
    }

    return _fromAdminPrefsOrSeed(prefs);
  }

  Future<void> syncFromAdminLocal() async {
    final prefs = await SharedPreferences.getInstance();
    final snapshot = await _fromAdminPrefsOrSeed(prefs);
    await _persist(snapshot);
  }

  Future<void> _persist(SiteAnimationCatalogSnapshot snapshot) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      siteAnimationCatalogPrefsKey,
      jsonEncode(_snapshotToJson(snapshot)),
    );
  }

  SiteAnimationCatalogSnapshot _parseApiPayload(dynamic data) {
    final root = asJsonMap(data is Map ? data : const {});
    final payload = asJsonMap(root['data'] ?? root);
    final list = (payload['animations'] ?? payload['items']) as List? ?? const [];
    final animations = <String, SiteAnimationCatalogEntry>{};
    for (final raw in list) {
      final entry = _entryFromJson(asJsonMap(raw));
      if (entry.id.isEmpty) continue;
      animations[entry.id] = entry;
    }
    return SiteAnimationCatalogSnapshot(
      animations: animations,
      entranceDefaults: _parseEntranceDefaults(payload['defaults'] ?? payload),
      exitDefaults: _parseExitDefaults(payload['exitDefaults']),
      userAssignments: _parseUserAssignments(payload['userAssignments']),
    );
  }

  SiteAnimationCatalogSnapshot _parseCached(Map<String, dynamic> json) {
    final animations = <String, SiteAnimationCatalogEntry>{};
    final rawList = json['animations'];
    if (rawList is List) {
      for (final item in rawList) {
        final entry = _entryFromJson(asJsonMap(item));
        if (entry.id.isEmpty) continue;
        animations[entry.id] = entry;
      }
    } else if (rawList is Map) {
      for (final item in rawList.values) {
        final entry = _entryFromJson(asJsonMap(item));
        if (entry.id.isEmpty) continue;
        animations[entry.id] = entry;
      }
    }

    return SiteAnimationCatalogSnapshot(
      animations: animations,
      entranceDefaults: _parseEntranceDefaults(json['entranceDefaults']),
      exitDefaults: _parseExitDefaults(json['exitDefaults']),
      userAssignments: _parseUserAssignments(json['userAssignments']),
    );
  }

  Future<SiteAnimationCatalogSnapshot> _fromAdminPrefsOrSeed(
    SharedPreferences prefs,
  ) async {
    final rawCatalog = prefs.getString(_adminCatalogKey);
    final List<AdminSiteAnimation> adminItems;
    if (rawCatalog != null) {
      final list = jsonDecode(rawCatalog) as List<dynamic>;
      adminItems = list
          .map((e) => AdminSiteAnimation.fromJson(asJsonMap(e)))
          .toList();
    } else {
      adminItems = AdminSiteAnimationSeedCatalog.all();
    }

    final animations = {
      for (final a in adminItems) a.id: _entryFromAdmin(a),
    };

    final defaultsRaw = prefs.getString(_adminDefaultsKey);
    final entranceDefaults = defaultsRaw != null
        ? _parseEntranceDefaults(jsonDecode(defaultsRaw))
        : _entranceDefaultsFromSeed();

    final exitDefaultsRaw = prefs.getString(_adminExitDefaultsKey);
    final exitDefaults = exitDefaultsRaw != null
        ? _parseExitDefaults(jsonDecode(exitDefaultsRaw))
        : _exitDefaultsFromSeed();

    final assignmentsRaw = prefs.getString(_adminAssignmentsKey);
    final userAssignments = assignmentsRaw != null
        ? _parseUserAssignments(jsonDecode(assignmentsRaw))
        : const <String, Map<SiteAnimationSlot, SiteAnimationUserAssignment>>{};

    return SiteAnimationCatalogSnapshot(
      animations: animations,
      entranceDefaults: entranceDefaults,
      exitDefaults: exitDefaults,
      userAssignments: userAssignments,
    );
  }

  Map<String, dynamic> _snapshotToJson(SiteAnimationCatalogSnapshot s) => {
        'animations': s.animations.values.map(_entryToJson).toList(),
        'entranceDefaults': {
          for (final e in s.entranceDefaults.entries) e.key.name: e.value,
        },
        'exitDefaults': {
          for (final e in s.exitDefaults.entries) e.key.name: e.value,
        },
        'userAssignments': _assignmentsToJson(s.userAssignments),
      };

  SiteAnimationCatalogEntry _entryFromAdmin(AdminSiteAnimation anim) {
    return SiteAnimationCatalogEntry(
      id: anim.id,
      name: anim.name,
      category: anim.category.name,
      tier: _tierFromMembership(anim.membership),
      animationType: anim.animationType,
      assetUrl: anim.assetUrl,
      previewMp4Key: anim.previewMp4Key,
      durationMs: anim.durationMs,
      priority: anim.priority,
      anchor: _anchorFromAdmin(anim.anchor),
      scale: anim.scale,
      isActive: anim.isActive,
      description: anim.description,
    );
  }

  SiteAnimationCatalogEntry _entryFromJson(Map<String, dynamic> json) {
    return SiteAnimationCatalogEntry(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? 'Animasyon',
      category: json['category']?.toString() ?? 'entrance',
      tier: _tierFromMembership(
        AdminSiteAnimationMembership.parse(json['membership']?.toString()),
      ),
      animationType: json['animationType']?.toString() ??
          json['assetType']?.toString() ??
          'native',
      assetUrl: json['assetUrl']?.toString() ?? json['animationUrl']?.toString(),
      previewMp4Key: json['previewMp4Key']?.toString(),
      durationMs: _int(json['durationMs'] ?? json['duration'], 3000),
      priority: _int(json['priority'], 50),
      anchor: _anchorFromWire(json['anchor']?.toString()),
      scale: _double(json['scale'], 1),
      isActive: json['isActive'] != false && json['active'] != false,
      description: json['description']?.toString(),
    );
  }

  Map<String, dynamic> _entryToJson(SiteAnimationCatalogEntry e) => {
        'id': e.id,
        'name': e.name,
        'category': e.category,
        'membership': e.tier.name,
        'animationType': e.animationType,
        if (e.assetUrl != null) 'assetUrl': e.assetUrl,
        if (e.previewMp4Key != null) 'previewMp4Key': e.previewMp4Key,
        'durationMs': e.durationMs,
        'priority': e.priority,
        'anchor': _anchorWire(e.anchor),
        'scale': e.scale,
        'isActive': e.isActive,
        if (e.description != null) 'description': e.description,
      };

  Map<SiteAnimationTier, String> _parseEntranceDefaults(dynamic raw) {
    if (raw is! Map) return _entranceDefaultsFromSeed();
    final out = <SiteAnimationTier, String>{};
    for (final e in raw.entries) {
      final tier = _tierFromMembership(
        AdminSiteAnimationMembership.parse(e.key.toString()),
      );
      final id = e.value?.toString();
      if (id != null && id.isNotEmpty) out[tier] = id;
    }
    return out.isEmpty ? _entranceDefaultsFromSeed() : out;
  }

  Map<SiteAnimationTier, String> _entranceDefaultsFromSeed() {
    final seed = AdminSiteAnimationSeedCatalog.defaultEntranceIds();
    return {
      for (final e in seed.entries) _tierFromMembership(e.key): e.value,
    };
  }

  Map<SiteAnimationTier, String> _exitDefaultsFromSeed() {
    final seed = AdminSiteAnimationSeedCatalog.defaultExitIds();
    return {
      for (final e in seed.entries) _tierFromMembership(e.key): e.value,
    };
  }

  Map<SiteAnimationTier, String> _parseExitDefaults(dynamic raw) {
    if (raw is! Map) return _exitDefaultsFromSeed();
    final out = <SiteAnimationTier, String>{};
    for (final e in raw.entries) {
      final tier = _tierFromMembership(
        AdminSiteAnimationMembership.parse(e.key.toString()),
      );
      final id = e.value?.toString();
      if (id != null && id.isNotEmpty) out[tier] = id;
    }
    return out.isEmpty ? _exitDefaultsFromSeed() : out;
  }

  Map<String, Map<SiteAnimationSlot, SiteAnimationUserAssignment>>
      _parseUserAssignments(dynamic raw) {
    if (raw is! Map) return const {};
    final out = <String, Map<SiteAnimationSlot, SiteAnimationUserAssignment>>{};
    for (final userEntry in raw.entries) {
      final userId = userEntry.key.toString();
      final map = asJsonMap(userEntry.value);
      final slots = <SiteAnimationSlot, SiteAnimationUserAssignment>{};
      for (final slot in SiteAnimationSlot.values) {
        final id = map[slot.name]?.toString();
        if (id == null || id.isEmpty) continue;
        final expiresRaw = map['${slot.name}_expiresAt']?.toString();
        slots[slot] = SiteAnimationUserAssignment(
          animationId: id,
          expiresAt:
              expiresRaw != null ? DateTime.tryParse(expiresRaw) : null,
        );
      }
      if (slots.isNotEmpty) out[userId] = slots;
    }
    return out;
  }

  Map<String, dynamic> _assignmentsToJson(
    Map<String, Map<SiteAnimationSlot, SiteAnimationUserAssignment>> raw,
  ) {
    final out = <String, dynamic>{};
    for (final userEntry in raw.entries) {
      final slotMap = <String, dynamic>{};
      for (final slotEntry in userEntry.value.entries) {
        slotMap[slotEntry.key.name] = slotEntry.value.animationId;
        if (slotEntry.value.expiresAt != null) {
          slotMap['${slotEntry.key.name}_expiresAt'] =
              slotEntry.value.expiresAt!.toIso8601String();
        }
      }
      out[userEntry.key] = slotMap;
    }
    return out;
  }

  SiteAnimationTier _tierFromMembership(
    AdminSiteAnimationMembership? membership,
  ) {
    return switch (membership) {
      AdminSiteAnimationMembership.gold => SiteAnimationTier.gold,
      AdminSiteAnimationMembership.premium => SiteAnimationTier.premium,
      AdminSiteAnimationMembership.diamond => SiteAnimationTier.diamond,
      AdminSiteAnimationMembership.vip => SiteAnimationTier.vip,
      AdminSiteAnimationMembership.svip => SiteAnimationTier.svip,
      AdminSiteAnimationMembership.admin => SiteAnimationTier.admin,
      AdminSiteAnimationMembership.host => SiteAnimationTier.host,
      _ => SiteAnimationTier.normal,
    };
  }

  SiteAnimationAnchor _anchorFromAdmin(AdminSiteAnimationAnchor anchor) {
    return switch (anchor) {
      AdminSiteAnimationAnchor.topCenter => SiteAnimationAnchor.topCenter,
      AdminSiteAnimationAnchor.seat => SiteAnimationAnchor.seat,
      AdminSiteAnimationAnchor.custom => SiteAnimationAnchor.custom,
      _ => SiteAnimationAnchor.topLeft,
    };
  }

  SiteAnimationAnchor _anchorFromWire(String? raw) {
    return switch (raw?.toUpperCase()) {
      'TOP_CENTER' || 'TOPCENTER' => SiteAnimationAnchor.topCenter,
      'SEAT' => SiteAnimationAnchor.seat,
      'CUSTOM' => SiteAnimationAnchor.custom,
      _ => SiteAnimationAnchor.topLeft,
    };
  }

  String _anchorWire(SiteAnimationAnchor anchor) => switch (anchor) {
        SiteAnimationAnchor.topCenter => 'TOP_CENTER',
        SiteAnimationAnchor.seat => 'SEAT',
        SiteAnimationAnchor.custom => 'CUSTOM',
        SiteAnimationAnchor.topLeft => 'TOP_LEFT',
      };

  static int _int(dynamic v, int fallback) {
    if (v is num) return v.toInt();
    return int.tryParse('$v') ?? fallback;
  }

  static double _double(dynamic v, double fallback) {
    if (v is num) return v.toDouble();
    return double.tryParse('$v') ?? fallback;
  }
}
