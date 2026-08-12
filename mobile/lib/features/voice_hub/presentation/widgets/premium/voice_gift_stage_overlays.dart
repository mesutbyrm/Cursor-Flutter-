import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../gifts/presentation/engine/gift_engine_seat_effects_overlay.dart';
import '../../../../gifts/presentation/engine/gift_feed_panel.dart';
import '../../../../gifts/presentation/sync/gift_session_controller.dart';
import '../../utils/voice_room_seat_capacity.dart';

/// Sesli oda HUD katmanı — feed + koltuk efektleri (UI üstünde).
class VoiceGiftHudOverlays extends ConsumerWidget {
  const VoiceGiftHudOverlays({
    super.key,
    required this.sessionKey,
    this.seatEffectBound = 12,
  });

  final String sessionKey;
  final int seatEffectBound;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeAnimation = ref.watch(
      giftSessionProvider(sessionKey).select((s) => s.activeAnimation),
    );

    return Stack(
      clipBehavior: Clip.none,
      fit: StackFit.passthrough,
      children: [
        GiftEngineSeatEffectsOverlay(
          event: activeAnimation,
          seatCount: seatEffectBound,
        ),
        GiftFeedPanel(sessionKey: sessionKey),
      ],
    );
  }
}

/// Geriye dönük alias — HUD katmanı.
typedef VoiceGiftStageOverlays = VoiceGiftHudOverlays;
