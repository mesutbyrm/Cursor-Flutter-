import '../../live/domain/entities/live_gift_event.dart';
import 'gift_entity.dart';

/// Backend render meta — SSE/HTTP hediye olaylarından tam ekran / sahne kararı.
abstract final class GiftRenderMeta {
  static bool isFullscreenLayer(LiveGiftEvent event, [GiftEntity? catalog]) {
    if (event.isFullscreen == true) return true;
    if (event.visibleAsFullscreen == true) return true;
    final dt = event.displayType?.toLowerCase();
    if (dt == 'fullscreen') return true;
    final pos = event.screenPosition?.toLowerCase();
    if (pos == 'fullscreen') return true;
    final tier = event.tier?.toLowerCase();
    if (tier == 'huge') return true;
    if (catalog?.isFullscreen == true) return true;
    if (catalog?.displayType.isFullscreenLayer == true) return true;
    final asset = event.assetType?.toLowerCase() ?? '';
    if (asset == 'video' && (event.isFullscreen == true || tier == 'huge')) {
      return true;
    }
    return false;
  }

  static bool isStageBandLayer(LiveGiftEvent event, [GiftEntity? catalog]) {
    if (isFullscreenLayer(event, catalog)) return false;
    final tier = event.tier?.toLowerCase();
    if (tier == 'big' || tier == 'huge') return true;
    final pos = event.screenPosition?.toLowerCase();
    if (pos == 'above_seat' ||
        pos == 'room_center' ||
        pos == 'center' ||
        pos == 'message_area') {
      return true;
    }
    final asset = event.assetType?.toLowerCase() ?? '';
    if (asset == 'video' || asset == 'lottie' || asset == 'svga') return true;
    if (catalog?.hasCmsAnimation == true) return true;
    return event.jetonAmount >= 100;
  }

  static Duration displayDuration(LiveGiftEvent event, [GiftEntity? catalog]) {
    final ms = event.displayDurationMs;
    if (ms != null && ms > 0) return Duration(milliseconds: ms.clamp(800, 20000));
    final catalogMs = catalog?.animationDurationMs;
    if (catalogMs != null && catalogMs > 0) {
      return Duration(milliseconds: catalogMs.clamp(1500, 12000));
    }
    return const Duration(milliseconds: 3500);
  }

  static String? animationUrl(LiveGiftEvent event, [GiftEntity? catalog]) {
    final url = event.assetUrl ?? event.animationKey;
    if (url != null && url.trim().isNotEmpty) return url.trim();
    return catalog?.networkAnimationUrl;
  }
}
