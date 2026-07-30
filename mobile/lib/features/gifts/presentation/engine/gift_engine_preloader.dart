import '../../../../core/video/video_cache_service.dart';
import '../../../live/domain/entities/live_gift_event.dart';
import '../../data/gift_cache_service.dart';
import '../../domain/gift_engine_models.dart';
import '../../domain/gift_engine_parser.dart';
import '../../domain/gift_media_type.dart';

/// Kuyruğa eklenen hediyelerin asset'lerini önceden yükler.
abstract final class GiftEnginePreloader {
  static Future<void> prefetch(LiveGiftEvent event) async {
    final config = GiftEngineParser.fromEvent(event);
    final urls = <String>{
      if (config.thumbnailUrl != null) config.thumbnailUrl!,
      if (event.displayImageUrl != null) event.displayImageUrl!,
      if (event.thumbnailUrl != null) event.thumbnailUrl!,
    };

    final mediaType = GiftMediaType.resolve(
      mediaType: event.mediaType ?? config.mediaType,
      assetType: event.assetType,
      assetFormat: event.assetFormat ?? config.assetFormat,
      animationType: event.engineAnimationType,
      url: config.videoUrl ?? config.resolvedAssetUrl,
    );

    final videoUrl = config.videoUrl ?? config.resolvedAssetUrl;
    if (mediaType.isVideo && videoUrl != null && videoUrl.startsWith('http')) {
      await VideoCacheService.instance.prefetch(videoUrl);
      unawaited(VideoCacheService.instance.warmController(videoUrl));
      return;
    }

    final asset = config.resolvedAssetUrl;
    if (asset != null) urls.add(asset);
    if (config.imageUrl != null) urls.add(config.imageUrl!);

    GiftCacheService.instance.prefetchUrls(
      urls.where((u) => u.startsWith('http')),
    );
  }
}
