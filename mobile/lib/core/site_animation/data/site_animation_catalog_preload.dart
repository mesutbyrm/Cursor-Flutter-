import 'dart:async';

import '../domain/site_animation_catalog_entry.dart';
import 'site_animation_cache.dart';
import 'site_animation_cdn_assets.dart';

/// Aktif katalog yüklendiğinde ses/asset ön belleğe alır.
abstract final class SiteAnimationCatalogPreload {
  static const _warmCategories = {'entrance', 'exit', 'transition', 'gift'};

  static Future<void> warm(SiteAnimationCatalogSnapshot snapshot) async {
    final futures = <Future<void>>[];
    for (final entry in snapshot.animations.values) {
      if (!entry.isActive) continue;

      final sound = entry.soundUrl?.trim();
      if (sound != null && sound.isNotEmpty) {
        futures.add(SiteAnimationCache.preloadSound(sound));
      }

      final category = entry.category.toLowerCase().trim();
      if (!_warmCategories.contains(category)) continue;

      final asset = SiteAnimationCdnAssets.runtimeAsset(entry);
      if (asset != null && asset.hasRemote) {
        futures.add(SiteAnimationCache.preload(asset));
      }
    }
    if (futures.isEmpty) return;
    await Future.wait(futures, eagerError: false);
  }
}
