import 'package:flutter/material.dart';

import 'fx_big_gift_banner.dart';
import 'fx_recent_gifts_strip.dart';
import '../providers/voice_room_campaign_provider.dart';

/// Sesli oda görsel efekt katmanı — hediye banner + son hediyeler + kampanya.
class FxVoiceRoomOverlayHost extends StatelessWidget {
  const FxVoiceRoomOverlayHost({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Stack(
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
    );
  }
}
