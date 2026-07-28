import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../gifts/presentation/engine/gift_engine_overlay.dart';
import '../../../../gifts/presentation/engine/gift_engine_seat_effects_overlay.dart';
import '../../../../gifts/presentation/engine/gift_feed_panel.dart';
import '../../../../gifts/presentation/sync/gift_session_controller.dart';
import '../../../../gifts/presentation/widgets/gift_stage_layout.dart';
import '../../providers/voice_room_ui_provider.dart';

/// Gift Engine — tek kuyruk, backend render, sohbet/koltuklar görünür kalır.
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

    return Stack(
      clipBehavior: Clip.none,
      fit: StackFit.passthrough,
      children: [
        GiftEngineSeatEffectsOverlay(event: activeAnimation),
        GiftEngineOverlay(
          event: activeAnimation,
          enabled: animationsEnabled,
          stage: stageContext,
          onFinished: (id) => ref
              .read(giftSessionProvider(sessionKey).notifier)
              .dequeueAnimation(id),
        ),
        GiftFeedPanel(sessionKey: sessionKey),
      ],
    );
  }
}
