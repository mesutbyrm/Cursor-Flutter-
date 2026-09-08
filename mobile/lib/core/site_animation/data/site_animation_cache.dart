import '../../../core/video/video_cache_service.dart';
import '../../../features/gifts/data/gift_cache_service.dart';
import '../domain/site_animation_asset.dart';

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

    if (url.startsWith('http')) {
      GiftCacheService.instance.prefetchUrls([url]);
    }
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
