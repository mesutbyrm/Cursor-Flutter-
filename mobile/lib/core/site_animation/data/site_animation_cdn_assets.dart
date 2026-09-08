import '../domain/site_animation_asset.dart';
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

  /// Katalog kaydından runtime preload asset'i.
  static SiteAnimationAsset? runtimeAsset(SiteAnimationCatalogEntry entry) {
    final resolvedUrl = resolveAssetUrl(entry);
    if (resolvedUrl == null || resolvedUrl.isEmpty) return null;
    return SiteAnimationAsset(
      url: resolvedUrl.startsWith('assets/') ? null : resolvedUrl,
      bundlePath: resolvedUrl.startsWith('assets/') ? resolvedUrl : null,
      kind: _mediaKind(entry.animationType, resolvedUrl),
      previewMp4Key: entry.previewMp4Key,
    );
  }

  static SiteAnimationMediaKind _mediaKind(String type, String url) {
    return switch (type.toLowerCase()) {
      'lottie' || 'json' => SiteAnimationMediaKind.lottie,
      'video' || 'mp4' || 'webm' => SiteAnimationMediaKind.video,
      'svga' => SiteAnimationMediaKind.svga,
      'rive' || 'riv' => SiteAnimationMediaKind.rive,
      _ => url.endsWith('.json') || url.endsWith('.lottie')
          ? SiteAnimationMediaKind.lottie
          : url.endsWith('.mp4') || url.endsWith('.webm')
              ? SiteAnimationMediaKind.video
              : SiteAnimationMediaKind.native,
    };
  }
}
