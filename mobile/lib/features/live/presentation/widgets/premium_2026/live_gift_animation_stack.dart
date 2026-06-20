import 'package:flutter/material.dart';

import '../../../../gifts/presentation/widgets/premium_2026/premium_gift_fullscreen_overlay.dart';
import '../../../domain/entities/live_gift_event.dart';

/// Aynı anda birden fazla tam ekran hediye animasyonu.
class LiveGiftAnimationStack extends StatelessWidget {
  const LiveGiftAnimationStack({
    super.key,
    required this.events,
  });

  final List<LiveGiftEvent> events;

  @override
  Widget build(BuildContext context) {
    if (events.isEmpty) return const SizedBox.shrink();
    return Stack(
      fit: StackFit.expand,
      children: [
        for (var i = 0; i < events.length && i < 3; i++)
          Positioned.fill(
            child: IgnorePointer(
              child: Opacity(
                opacity: 1.0 - (i * 0.22),
                child: PremiumGiftFullscreenOverlay(event: events[i]),
              ),
            ),
          ),
      ],
    );
  }
}
