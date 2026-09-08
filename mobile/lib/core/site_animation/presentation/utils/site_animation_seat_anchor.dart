import 'package:flutter/material.dart';

import 'site_animation_voice_room_layout.dart';

/// Koltuk indeksinden ekran koordinatı — `VoiceWebOwnerStage` ile hizalı.
class SiteAnimationSeatAnchor {
  const SiteAnimationSeatAnchor._();

  static Rect seatRect({
    required BuildContext context,
    required int seatIndex,
    int cols = 4,
    double topBase = 108,
    double rowHeight = 84,
    double seatSize = 64,
    double horizontalPad = 12,
  }) {
    final scope = SiteAnimationVoiceRoomLayoutScope.maybeOf(context);
    if (scope != null) {
      return SiteAnimationVoiceRoomLayout.seatRect(
        context,
        seatIndex,
        stageTop: scope.stageTop,
      );
    }
    final w = MediaQuery.sizeOf(context).width;
    final col = seatIndex % cols;
    final row = seatIndex ~/ cols;
    final cellW = (w - horizontalPad * 2) / cols;
    final left = horizontalPad + col * cellW + (cellW - seatSize) / 2;
    final top = topBase + row * rowHeight;
    return Rect.fromLTWH(left, top, seatSize, seatSize);
  }

  static Offset seatCenter(BuildContext context, int seatIndex) {
    final rect = seatRect(context: context, seatIndex: seatIndex);
    return rect.center;
  }
}
