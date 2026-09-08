import '../../../core/video/video_cache_service.dart';
import '../../../features/gifts/data/gift_cache_service.dart';
import '../domain/site_animation_asset.dart';

/// CDN asset pipeline: `…/animations/{source|preview|production}/{id}.{ext}`
abstract final class SiteAnimationAssetPaths {
  static const cdnBase = 'https://cdn.canlifal.com/animations';

  static String production(String animationId, {String ext = 'lottie'}) =>
      '$cdnBase/production/$animationId.$ext';

  static String preview(String animationId) =>
      '$cdnBase/preview/$animationId.mp4';

  static String sound(String animationId) =>
      '$cdnBase/sounds/$animationId.mp3';
}

/// Site animation asset önbelleği — tekrar indirmeyi engeller.
abstract final class SiteAnimationCache {
  static Future<void> preload(SiteAnimationAsset asset) async {
    final url = asset.url?.trim();
    if (url == null || url.isEmpty) return;

    if (asset.kind == SiteAnimationMediaKind.video ||
        url.endsWith('.mp4') ||
        url.endsWith('.webm')) {
      await VideoCacheService.instance.prefetch(url);
      return;
    }

    if (asset.kind == SiteAnimationMediaKind.lottie ||
        url.endsWith('.json') ||
        url.endsWith('.lottie')) {
      GiftCacheService.instance.prefetchUrls([url]);
      return;
    }

    if (asset.kind == SiteAnimationMediaKind.rive || url.endsWith('.riv')) {
      GiftCacheService.instance.prefetchUrls([url]);
    }
  }

  static Future<void> preloadSound(String? url) async {
    final u = url?.trim();
    if (u == null || u.isEmpty || !u.startsWith('http')) return;
    GiftCacheService.instance.prefetchUrls([u]);
  }

  static Future<bool> isCached(SiteAnimationAsset asset) async {
    final url = asset.url?.trim();
    if (url == null || url.isEmpty) return asset.hasBundle;
    if (asset.kind == SiteAnimationMediaKind.video ||
        url.endsWith('.mp4') ||
        url.endsWith('.webm')) {
      final file = await VideoCacheService.instance.peekCachedFile(url);
      return file != null;
    }
    return true;
  }
}
