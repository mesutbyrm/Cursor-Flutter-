import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../profile/presentation/widgets/premium/profile_glass.dart';
import '../../../domain/entities/live_gift_catalog.dart';
import '../../../domain/entities/live_gift_event.dart';

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
            padding: const EdgeInsets.only(bottom: 6),
            child: _GiftBanner(event: e)
                .animate(key: ValueKey(e.id))
                .fadeIn(duration: 220.ms)
                .slideX(begin: -0.15, end: 0),
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
    final combo = event.combo > 1 ? ' x${event.combo}' : '';

    return ProfileGlass(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      borderRadius: 18,
      blur: 12,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          boxShadow: AppColors.glowShadow(AppColors.accentPink, blur: 18),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 22)),
            const SizedBox(width: 8),
            Flexible(
              child: RichText(
                text: TextSpan(
                  style: const TextStyle(fontSize: 12, height: 1.25),
                  children: [
                    TextSpan(
                      text: event.senderName,
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        color: AppColors.accentCyan,
                      ),
                    ),
                    const TextSpan(
                      text: ' → ',
                      style: TextStyle(color: AppColors.textMuted),
                    ),
                    TextSpan(
                      text: event.receiverName,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                    TextSpan(
                      text: ' ${event.quantity > 1 ? '${event.quantity} ' : ''}${event.giftName}$combo',
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        color: AppColors.accentPink,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
