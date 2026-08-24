import 'package:flutter/material.dart';
import 'package:canlifal_social/core/images/canlifal_network_image.dart';
import 'package:canlifal_social/core/theme/app_theme_colors.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../domain/entities/live_gift_catalog.dart';
import '../../../domain/entities/live_gift_event.dart';

/// Chat üstü hediye bildirimi — kompakt, gönderen + jeton net görünür.
class GiftNotificationStack extends StatelessWidget {
  const GiftNotificationStack({super.key, required this.events});

  final List<LiveGiftEvent> events;

  @override
  Widget build(BuildContext context) {
    if (events.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final e in events.take(2))
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: _GiftBanner(event: e)
                .animate(key: ValueKey(e.id))
                .fadeIn(duration: 220.ms)
                .slideX(begin: -0.08, end: 0)
                .then(delay: const Duration(seconds: 4))
                .fadeOut(duration: 450.ms, curve: Curves.easeOut),
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
    final qtyLabel = event.quantity > 1 ? ' ×${event.quantity}' : '';
    final imageUrl = event.displayImageUrl;
    final totalJeton = jeton;

    return RepaintBoundary(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 280),
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              colors: [
                AppThemeColors.accentPink.withValues(alpha: 0.42),
                const Color(0xFF2A1048).withValues(alpha: 0.92),
              ],
            ),
            border: Border.all(
              color: const Color(0xFFFFD54F).withValues(alpha: 0.55),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: AppThemeColors.accentPink.withValues(alpha: 0.35),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (imageUrl != null)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: CanlifalNetworkImage(
                      url: imageUrl,
                      width: 36,
                      height: 36,
                      fit: BoxFit.cover,
                      errorWidget:
                          Text(emoji, style: const TextStyle(fontSize: 26)),
                    ),
                  )
                else
                  Text(emoji, style: const TextStyle(fontSize: 26)),
                const SizedBox(width: 8),
                Flexible(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        event.senderName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 13,
                          height: 1.15,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${event.giftName}$qtyLabel',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 11,
                          height: 1.15,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFFFF8EC7),
                        ),
                      ),
                      if (totalJeton > 0) ...[
                        const SizedBox(height: 2),
                        Text(
                          '🪙 $totalJeton jeton',
                          style: TextStyle(
                            fontSize: 12,
                            height: 1.1,
                            fontWeight: FontWeight.w800,
                            color: Colors.amber.shade200,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
