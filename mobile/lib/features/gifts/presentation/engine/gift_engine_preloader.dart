import '../../../live/domain/entities/live_gift_event.dart';
import '../../data/gift_cache_service.dart';
import '../../domain/gift_engine_parser.dart';

/// Kuyruğa eklenen hediyelerin asset'lerini önceden yükler.
abstract final class GiftEnginePreloader {
  static Future<void> prefetch(LiveGiftEvent event) async {
    final config = GiftEngineParser.fromEvent(event);
    final urls = <String>{
      if (config.resolvedAssetUrl != null) config.resolvedAssetUrl!,
      if (config.imageUrl != null) config.imageUrl!,
      if (config.videoUrl != null) config.videoUrl!,
      if (config.thumbnailUrl != null) config.thumbnailUrl!,
      if (event.displayImageUrl != null) event.displayImageUrl!,
    };
    GiftCacheService.instance.prefetchUrls(
      urls.where((u) => u.startsWith('http')),
    );
  }
}
