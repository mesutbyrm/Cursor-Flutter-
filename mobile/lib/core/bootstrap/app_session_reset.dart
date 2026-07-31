import '../../features/gifts/data/gift_cache_service.dart';
import '../video/video_cache_service.dart';

/// Soğuk açılış — önceki oturumdan kalan sıcak kaynakları temizler.
abstract final class AppSessionReset {
  static void onColdStart() {
    VideoCacheService.instance.disposeAllWarm();
    GiftCacheService.instance.clearMemory();
  }
}
