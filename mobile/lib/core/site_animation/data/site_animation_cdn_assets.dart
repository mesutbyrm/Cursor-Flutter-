import '../domain/site_animation_catalog_entry.dart';
import 'site_animation_cache.dart';

/// CDN asset URL çözümleme — bundle yoksa production path dener.
abstract final class SiteAnimationCdnAssets {
  static String? resolveAssetUrl(SiteAnimationCatalogEntry entry) {
    final direct = entry.assetUrl?.trim();
    if (direct != null && direct.isNotEmpty) return direct;

    final type = entry.animationType.toLowerCase();
    return switch (type) {
      'lottie' || 'json' =>
        SiteAnimationAssetPaths.production(entry.id, ext: 'lottie'),
      'rive' || 'riv' =>
        SiteAnimationAssetPaths.production(entry.id, ext: 'riv'),
      'video' || 'mp4' =>
        SiteAnimationAssetPaths.production(entry.id, ext: 'mp4'),
      _ => null,
    };
  }
}
