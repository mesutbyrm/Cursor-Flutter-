import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../gifts/presentation/widgets/gift_animation_player.dart';
import '../../../domain/entities/live_gift_event.dart';

class GiftFullscreenOverlay extends StatelessWidget {
  const GiftFullscreenOverlay({super.key, this.event});

  final LiveGiftEvent? event;

  @override
  Widget build(BuildContext context) {
    if (event == null) return const SizedBox.shrink();
    final e = event!;
    final glow = e.rarity.glowColor;

    return IgnorePointer(
      child: Stack(
        fit: StackFit.expand,
        children: [
          Container(color: Colors.black.withValues(alpha: 0.42))
              .animate()
              .fadeIn(duration: 180.ms),
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DecoratedBox(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: AppColors.glowShadow(glow, blur: 36),
                  ),
                  child: GiftAnimationPlayer(
                    giftId: e.giftId,
                    event: e,
                    size: 240,
                  ),
                ),
                const SizedBox(height: 14),
                if (e.combo > 1)
                  Text(
                    'COMBO x${e.combo}',
                    style: TextStyle(
                      fontSize: 40,
                      fontWeight: FontWeight.w900,
                      foreground: Paint()
                        ..shader = AppColors.brandGradient.createShader(
                          const Rect.fromLTWH(0, 0, 220, 48),
                        ),
                      shadows: [Shadow(color: glow.withValues(alpha: 0.8), blurRadius: 16)],
                    ),
                  ).animate().scale(
                        begin: const Offset(0.4, 0.4),
                        end: const Offset(1, 1),
                        duration: 450.ms,
                        curve: Curves.elasticOut,
                      ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.55),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: glow.withValues(alpha: 0.5)),
                  ),
                  child: Text(
                    e.notificationText,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                    ),
                  ),
                ),
              ],
            ),
          ).animate().fadeIn(duration: 260.ms).scale(
                begin: const Offset(0.65, 0.65),
                end: const Offset(1, 1),
                curve: Curves.easeOutBack,
              ),
        ],
      ),
    );
  }
}
