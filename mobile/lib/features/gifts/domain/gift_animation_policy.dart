import 'gift_display_type.dart';
import 'gift_entity.dart';

/// Web ↔ Flutter hediye animasyon paritesi — hediye sistemi dokümanı §6–8.
abstract final class GiftAnimationPolicy {
  static const luxuryJetonThreshold = 500;
  static const expensiveJetonThreshold = 200;
  static const midJetonThreshold = 100;

  static const fullscreenFlashDuration = Duration(milliseconds: 600);
  static const queueGapDuration = Duration(milliseconds: 300);

  /// FIFO kuyruk oynatma süresi (fiyat eşikleri).
  static Duration queueDuration({
    required int jetonPrice,
    int? animationDurationMs,
  }) {
    if (animationDurationMs != null && animationDurationMs > 0) {
      return Duration(milliseconds: animationDurationMs);
    }
    if (jetonPrice >= luxuryJetonThreshold) {
      return const Duration(seconds: 5);
    }
    if (jetonPrice >= midJetonThreshold) {
      return const Duration(seconds: 4);
    }
    return const Duration(seconds: 3);
  }

  static Duration fullscreenDuration({
    required int jetonPrice,
    int? animationDurationMs,
  }) {
    final base = queueDuration(
      jetonPrice: jetonPrice,
      animationDurationMs: animationDurationMs,
    );
    if (shouldFullscreenFlash(jetonPrice)) {
      return base + fullscreenFlashDuration;
    }
    return base;
  }

  static bool shouldFullscreenFlash(int jetonPrice) =>
      jetonPrice >= expensiveJetonThreshold;

  static bool shouldFullscreen({
    GiftEntity? catalog,
    required int jetonPrice,
    GiftDisplayType? displayType,
    bool hasNetworkAnimation = false,
  }) {
    if (catalog?.isFullscreen == true) return true;
    final dt = displayType ?? catalog?.displayType;
    if (dt != null && dt.isFullscreenLayer) return true;
    if (hasNetworkAnimation && jetonPrice >= expensiveJetonThreshold) {
      return true;
    }
    return jetonPrice >= expensiveJetonThreshold;
  }
}
