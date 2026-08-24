import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../domain/cosmetic_item.dart';
import '../domain/cosmetic_slot.dart';

/// Profil çerçevesi kataloğu — 30 dk disk önbelleği.
class CosmeticsCatalogCache {
  CosmeticsCatalogCache(this._prefs);

  final SharedPreferences _prefs;
  static const _key = 'cosmetics_profile_frames_cache_v1';
  static const _ttl = Duration(minutes: 30);

  Future<List<CosmeticItem>?> read() async {
    final raw = _prefs.getString(_key);
    if (raw == null || raw.isEmpty) return null;
    try {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      final at = DateTime.tryParse(map['at']?.toString() ?? '');
      if (at == null || DateTime.now().difference(at) > _ttl) return null;
      final items = map['items'];
      if (items is! List) return null;
      return items
          .whereType<Map>()
          .map((e) => CosmeticItem.fromJson(Map<String, dynamic>.from(e)))
          .where((c) => c.id.isNotEmpty)
          .toList();
    } catch (_) {
      return null;
    }
  }

  Future<void> write(List<CosmeticItem> items) async {
    final payload = jsonEncode({
      'at': DateTime.now().toIso8601String(),
      'items': items
          .map(
            (c) => {
              'id': c.id,
              'slot': c.slot.apiKey,
              'name': c.name,
              'effectType': c.effectKind.name,
              'previewUrl': c.previewUrl,
              'assetUrl': c.assetUrl,
              'tier': c.requiredTier.name,
              'requiredRole': c.requiredRole,
              'active': c.active,
              'sortOrder': c.sortOrder,
            },
          )
          .toList(),
    });
    await _prefs.setString(_key, payload);
  }
}
