import '../../features/gifts/data/gift_cache_service.dart';
import '../../features/trtc/presentation/trtc_room_manager.dart';
import '../images/canlifal_image_cache.dart';
import '../video/video_cache_service.dart';
import 'app_startup_log.dart';

/// Soğuk açılış — önceki oturumdan kalan sıcak kaynakları temizler.
abstract final class AppSessionReset {
  static void onColdStart() {
    AppStartupLog.log('APP_COLD_START_RESET');
    VideoCacheService.instance.disposeAllWarm();
    GiftCacheService.instance.clearMemory();
    CanlifalImageCache.trimIfNeeded();
    TrtcRoomManager.destroyEngine();
  }
}
