import '../../../../core/images/canlifal_image_cache.dart';
import '../../../../core/video/video_cache_service.dart';
import '../../../gifts/data/gift_cache_service.dart';
import '../../data/services/voice_room_gift_realtime_service.dart';
import '../../../live/data/services/live_gift_realtime_service.dart';

/// Oda oturumu bittiğinde yerel önbellekleri temizler.
abstract final class RoomSessionCache {
  static void clearOnRoomExit({
    VoiceRoomGiftRealtimeService? voiceGiftRealtime,
    LiveGiftRealtimeService? liveGiftRealtime,
  }) {
    GiftCacheService.instance.clearMemory();
    VideoCacheService.instance.disposeAllWarm();
    CanlifalImageCache.trimIfNeeded();
    voiceGiftRealtime?.resetDedupeState();
    liveGiftRealtime?.resetDedupeState();
  }
}
