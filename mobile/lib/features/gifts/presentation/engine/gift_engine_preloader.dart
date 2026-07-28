import '../../../live/domain/entities/live_gift_event.dart';
import '../../data/gift_cache_service.dart';
import '../../domain/gift_engine_models.dart';
import '../../domain/gift_engine_parser.dart';

/// Kuyruğa eklenen hediyelerin küçük asset'lerini önceden yükler.
/// Video dosyaları tam indirilmez — VideoPlayer akış yapar.
abstract final class GiftEnginePreloader {
  static Future<void> prefetch(LiveGiftEvent event) async {
    final config = GiftEngineParser.fromEvent(event);
    final urls = <String>{
      if (config.thumbnailUrl != null) config.thumbnailUrl!,
      if (event.displayImageUrl != null) event.displayImageUrl!,
    };
    final animType = config.animationType;
    if (animType != GiftEngineAnimationType.mp4 &&
        animType != GiftEngineAnimationType.webm) {
      final asset = config.resolvedAssetUrl;
      if (asset != null) urls.add(asset);
      if (config.imageUrl != null) urls.add(config.imageUrl!);
    }
    GiftCacheService.instance.prefetchUrls(
      urls.where((u) => u.startsWith('http')),
    );
  }
}
