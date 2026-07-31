import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../domain/gift_entity.dart';

/// CMS hediye kataloğu — versiyon + disk önbelleği.
class GiftCatalogSyncCache {
  GiftCatalogSyncCache(this._prefs);

  final SharedPreferences _prefs;
  static const _versionKey = 'gift_catalog_version_v1';
  static const _catalogKey = 'gift_catalog_items_v1';

  int readVersion() => _prefs.getInt(_versionKey) ?? 0;

  Future<void> writeVersion(int version) async {
    await _prefs.setInt(_versionKey, version);
  }

  Future<void> clear() async {
    await _prefs.remove(_versionKey);
    await _prefs.remove(_catalogKey);
  }

  List<GiftEntity> readCatalog({required String siteOrigin}) {
    final raw = _prefs.getString(_catalogKey);
    if (raw == null || raw.isEmpty) return const [];
    try {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      final items = map['items'];
      if (items is! List) return const [];
      return items
          .whereType<Map>()
          .map((e) => GiftEntity.fromJson(
                Map<String, dynamic>.from(e),
                siteOrigin: siteOrigin,
              ))
          .where((g) => g.id.isNotEmpty)
          .toList();
    } catch (_) {
      return const [];
    }
  }

  Future<void> clearCorrupt() async {
    await clear();
  }

  Future<void> writeCatalog(List<GiftEntity> gifts) async {
    final payload = jsonEncode({
      'at': DateTime.now().toIso8601String(),
      'items': gifts
          .map(
            (g) => {
              'id': g.id,
              'name': g.name,
              'price': g.price,
              'icon': g.iconUrl,
              if (g.iconEmoji != null) 'iconEmoji': g.iconEmoji,
              if (g.thumbnailUrl != null) 'thumbnailUrl': g.thumbnailUrl,
              if (g.assetUrl != null) 'assetUrl': g.assetUrl,
              'animation': g.animationRef,
              'animationType': g.animationKind.name,
              'rarity': g.rarity.name,
              'platform': g.platform.name,
              'sound': g.soundKey,
              'sortOrder': g.sortOrder,
              'isLucky': g.isLucky,
              if (g.collectionId != null) 'collectionId': g.collectionId,
              if (g.soundUrl != null) 'soundUrl': g.soundUrl,
              if (g.animationDurationMs > 0)
                'animationDurationMs': g.animationDurationMs,
              'isFullscreen': g.isFullscreen,
              'isPremium': g.isPremium,
              'comboEnabled': g.comboEnabled,
              'assetType': g.assetType.name,
              if (g.mediaType != null) 'mediaType': g.mediaType,
              if (g.assetFormat != null) 'assetFormat': g.assetFormat,
              if (g.mediaWidth != null) 'mediaWidth': g.mediaWidth,
              if (g.mediaHeight != null) 'mediaHeight': g.mediaHeight,
              if (g.networkAnimationUrl != null)
                'animationUrl': g.networkAnimationUrl,
            },
          )
          .toList(),
    });
    await _prefs.setString(_catalogKey, payload);
  }
}
