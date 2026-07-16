import 'package:flutter/material.dart';
import 'package:canlifal_social/core/images/canlifal_network_image.dart';
import 'package:canlifal_social/core/theme/app_theme_colors.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../domain/entities/live_gift_catalog.dart';
import '../../../domain/entities/live_gift_event.dart';

/// Chat üstü hediye bildirimi — büyük font, gradient/glow, 3 sn sonra kaybolur.
class GiftNotificationStack extends StatelessWidget {
  const GiftNotificationStack({super.key, required this.events});

  final List<LiveGiftEvent> events;

  @override
  Widget build(BuildContext context) {
    if (events.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final e in events.take(3))
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: _GiftBanner(event: e)
                .animate(key: ValueKey(e.id))
                .fadeIn(duration: 280.ms)
                .slideX(begin: -0.12, end: 0)
                .then(delay: const Duration(seconds: 3))
                .fadeOut(duration: 600.ms, curve: Curves.easeOut),
          ),
      ],
    );
  }
}

class _GiftBanner extends StatelessWidget {
  const _GiftBanner({required this.event});

  final LiveGiftEvent event;

  @override
  Widget build(BuildContext context) {
    final emoji = LiveGiftCatalog.emojiById[event.giftId] ?? '🎁';
    final jeton = event.jetonAmount;
    final qtyLabel = event.quantity > 1 ? ' x${event.quantity}' : '';
    final imageUrl = event.displayImageUrl;

    return RepaintBoundary(
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            colors: [
              AppThemeColors.accentPink.withValues(alpha: 0.35),
              AppThemeColors.accentCyan.withValues(alpha: 0.28),
              Colors.black.withValues(alpha: 0.55),
            ],
          ),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.28),
            width: 1.2,
          ),
          boxShadow: [
            ...AppThemeColors.glowShadow(AppThemeColors.accentPink, blur: 28),
            ...AppThemeColors.glowShadow(AppThemeColors.accentCyan, blur: 18),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              if (imageUrl != null)
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: CanlifalNetworkImage(
                    url: imageUrl,
                    width: 44,
                    height: 44,
                    fit: BoxFit.cover,
                    errorWidget: Text(emoji, style: const TextStyle(fontSize: 32)),
                  ),
                )
              else
                Text(emoji, style: const TextStyle(fontSize: 32)),
              const SizedBox(width: 10),
              Flexible(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '👤 ${event.senderName}',
                      style: TextStyle(
                        fontSize: 36,
                        height: 1.1,
                        fontWeight: FontWeight.w900,
                        foreground: Paint()
                          ..shader = LinearGradient(
                            colors: [
                              AppThemeColors.accentCyan,
                              Colors.white,
                            ],
                          ).createShader(const Rect.fromLTWH(0, 0, 200, 40)),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '🌹 ${event.giftName}$qtyLabel',
                      style: const TextStyle(
                        fontSize: 33,
                        height: 1.1,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFFFF8EC7),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      jeton > 0 ? '$jeton Jeton gönderdi' : 'Hediye gönderdi',
                      style: TextStyle(
                        fontSize: 30,
                        height: 1.1,
                        fontWeight: FontWeight.w700,
                        color: Colors.amber.shade200,
                        shadows: [
                          Shadow(
                            color: Colors.amber.withValues(alpha: 0.6),
                            blurRadius: 12,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
