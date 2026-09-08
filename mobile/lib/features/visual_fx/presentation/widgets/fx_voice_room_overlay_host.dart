import 'package:flutter/material.dart';

import '../../../../core/site_animation/presentation/utils/site_animation_voice_room_layout.dart';
import '../../../../core/site_animation/presentation/widgets/site_animation_overlay_host.dart';
import 'fx_big_gift_banner.dart';
import 'fx_recent_gifts_strip.dart';
import '../providers/voice_room_campaign_provider.dart';

/// Sesli oda görsel efekt katmanı — hediye banner + site animation + son hediyeler.
class FxVoiceRoomOverlayHost extends StatelessWidget {
  const FxVoiceRoomOverlayHost({
    super.key,
    required this.child,
    this.roomId = '',
  });

  final Widget child;
  final String roomId;

  @override
  Widget build(BuildContext context) {
    return SiteAnimationVoiceRoomLayoutScope(
      stageTop: 0,
      child: SiteAnimationOverlayHost(
        roomId: roomId,
        child: Stack(
          fit: StackFit.expand,
          clipBehavior: Clip.none,
          children: [
            child,
            const FxBigGiftBanner(),
            const Positioned(
              left: 8,
              bottom: 8,
              child: FxRecentGiftsStrip(),
            ),
            const Positioned(
              top: 0,
              right: 0,
              child: FxVoiceRoomCampaignBox(),
            ),
          ],
        ),
      ),
    );
  }
}
