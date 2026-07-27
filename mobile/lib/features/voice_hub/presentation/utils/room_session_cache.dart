import '../../../../core/images/canlifal_image_cache.dart';
import '../../../gifts/data/gift_cache_service.dart';

/// Oda oturumu bittiğinde yerel önbellekleri temizler.
abstract final class RoomSessionCache {
  static void clearOnRoomExit() {
    GiftCacheService.instance.clear();
    CanlifalImageCache.trimIfNeeded();
  }
}
