import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lottie/lottie.dart';

import '../../../../../core/theme/app_design.dart';
import '../../../domain/entities/live_gift_catalog.dart';
import '../../../domain/entities/live_gift_event.dart';

class GiftFullscreenOverlay extends StatelessWidget {
  const GiftFullscreenOverlay({super.key, this.event});

  final LiveGiftEvent? event;

  @override
  Widget build(BuildContext context) {
    if (event == null) return const SizedBox.shrink();
    final e = event!;
    final asset = LiveGiftCatalog.lottieAssetById[e.giftId];
    final emoji = LiveGiftCatalog.emojiById[e.giftId] ?? '🎁';

    return IgnorePointer(
      child: Stack(
        fit: StackFit.expand,
        children: [
          Container(
            color: Colors.black.withValues(alpha: 0.35),
          ).animate().fadeIn(duration: 200.ms),
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (asset != null)
                  SizedBox(
                    width: 220,
                    height: 220,
                    child: Lottie.asset(
                      asset,
                      repeat: false,
                      fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) => Text(
                        emoji,
                        style: const TextStyle(fontSize: 96),
                      ),
                    ),
                  )
                else
                  Text(emoji, style: const TextStyle(fontSize: 96)),
                const SizedBox(height: 12),
                if (e.combo > 1)
                  Text(
                    'COMBO x${e.combo}',
                    style: TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.w900,
                      foreground: Paint()
                        ..shader = AppDesign.heroGradient.createShader(
                          const Rect.fromLTWH(0, 0, 200, 40),
                        ),
                    ),
                  ).animate().scale(
                        begin: const Offset(0.5, 0.5),
                        end: const Offset(1, 1),
                        duration: 400.ms,
                        curve: Curves.elasticOut,
                      ),
                const SizedBox(height: 8),
                Text(
                  e.notificationText,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ).animate().fadeIn(duration: 280.ms).scale(
                begin: const Offset(0.7, 0.7),
                end: const Offset(1, 1),
                curve: Curves.easeOutBack,
              ),
        ],
      ),
    );
  }
}
