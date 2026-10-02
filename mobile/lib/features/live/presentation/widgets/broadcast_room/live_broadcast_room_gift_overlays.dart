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
    this.clipToVideoRegion = false,
  });

  final String streamId;
  final dynamic activeGift;

  /// PK split: animasyonlar skor şeridinin üstünü kapatmasın.
  final bool clipToVideoRegion;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(liveBroadcastSettingsProvider);
    final h = MediaQuery.sizeOf(context).height;
    final giftClipHeight = clipToVideoRegion ? h * 0.58 : h;
    Widget giftStack({required Widget child}) {
      if (!clipToVideoRegion) {
        return Positioned.fill(child: child);
      }
      return Positioned(
        top: 0,
        left: 0,
        right: 0,
        height: giftClipHeight,
        child: ClipRect(child: child),
      );
    }

    return Stack(
      fit: StackFit.expand,
      children: [
        giftStack(
          child: GiftEngineSeatEffectsOverlay(event: activeGift),
        ),
        giftStack(
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
        GiftFeedPanel(
          sessionKey: streamId,
          topFraction: clipToVideoRegion ? 0.57 : 0.40,
          maxWidth: clipToVideoRegion ? 220 : 270,
        ),
      ],
    );
  }
}
