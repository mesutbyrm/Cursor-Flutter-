import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../gifts/presentation/engine/gift_engine_overlay.dart';
import '../../../../gifts/presentation/engine/gift_engine_seat_effects_overlay.dart';
import '../../../../gifts/presentation/engine/gift_feed_panel.dart';
import '../../../../gifts/presentation/widgets/gift_stage_layout.dart';
import '../../../../gifts/presentation/sync/gift_session_controller.dart';
import '../../providers/live_broadcast_settings_provider.dart';

/// Canlı yayın — hediye motoru + kuyruk paneli (video/chat katmanından ayrı).
class LiveBroadcastRoomGiftOverlays extends ConsumerWidget {
  const LiveBroadcastRoomGiftOverlays({
    super.key,
    required this.streamId,
    required this.activeGift,
  });

  final String streamId;
  final dynamic activeGift;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(liveBroadcastSettingsProvider);
    return Stack(
      fit: StackFit.expand,
      children: [
        GiftEngineSeatEffectsOverlay(event: activeGift),
        Positioned.fill(
          child: IgnorePointer(
            child: GiftEngineOverlay(
              event: activeGift,
              enabled: settings.giftsEnabled,
              stage: GiftStageContext.liveStream,
              sessionKey: streamId,
              onFinished: (id) {
                ref
                    .read(giftSessionProvider(streamId).notifier)
                    .dequeueAnimation(id);
              },
            ),
          ),
        ),
        GiftFeedPanel(sessionKey: streamId),
      ],
    );
  }
}
