import 'package:flutter/material.dart';

import '../../../../gifts/presentation/widgets/premium_2026/premium_gift_fullscreen_overlay.dart';
import '../../../domain/entities/live_gift_event.dart';

/// Canlı yayın — premium tam ekran hediye (PART 4).
class GiftFullscreenOverlay extends StatelessWidget {
  const GiftFullscreenOverlay({super.key, this.event});

  final LiveGiftEvent? event;

  @override
  Widget build(BuildContext context) {
    return PremiumGiftFullscreenOverlay(event: event);
  }
}
