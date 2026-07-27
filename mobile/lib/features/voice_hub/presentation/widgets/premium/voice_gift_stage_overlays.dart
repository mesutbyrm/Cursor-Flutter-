import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../gifts/presentation/sync/gift_session_controller.dart';
import '../../../../gifts/presentation/widgets/gift_fullscreen_cover_overlay.dart';
import '../../../../gifts/presentation/widgets/gift_stage_layout.dart';
import '../../../../live/domain/entities/live_gift_event.dart';
import '../../providers/voice_room_ui_provider.dart';
import 'voice_gift_flight_overlay.dart';

/// Hediye animasyonları — yalnızca bu widget giftSession dinler; oda sayfası yeniden çizilmez.
class VoiceGiftStageOverlays extends ConsumerWidget {
  const VoiceGiftStageOverlays({
    super.key,
    required this.sessionKey,
    this.stageContext = GiftStageContext.voiceRoom,
  });

  final String sessionKey;
  final GiftStageContext stageContext;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final animationsEnabled = ref.watch(
      voiceRoomUiProvider.select((s) => s.giftAnimationsEnabled),
    );
    final activeAnimation = ref.watch(
      giftSessionProvider(sessionKey).select((s) => s.activeAnimation),
    );
    final activeFullscreen = ref.watch(
      giftSessionProvider(sessionKey).select((s) => s.activeFullscreen),
    );
    final flightEvents = activeAnimation != null
        ? [activeAnimation]
        : const <LiveGiftEvent>[];

    return Stack(
      clipBehavior: Clip.none,
      fit: StackFit.passthrough,
      children: [
        VoiceGiftFlightOverlay(
          events: flightEvents,
          enabled: animationsEnabled,
          stageContext: stageContext,
          onFinished: (id) => ref
              .read(giftSessionProvider(sessionKey).notifier)
              .dequeueAnimation(id),
        ),
        if (animationsEnabled && activeFullscreen != null)
          Positioned.fill(
            child: GiftFullscreenCoverOverlay(
              event: activeFullscreen,
              stage: stageContext,
            ),
          ),
      ],
    );
  }
}
