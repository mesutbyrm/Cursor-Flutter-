import 'package:flutter/material.dart';
import 'package:canlifal_social/core/images/canlifal_network_image.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../domain/entities/live_gift_catalog.dart';
import '../../../domain/entities/live_gift_event.dart';

/// Ortada gösterilen hediye bildirimi.
class GiftCenterToastStack extends StatelessWidget {
  const GiftCenterToastStack({super.key, required this.events});

  final List<LiveGiftEvent> events;

  @override
  Widget build(BuildContext context) {
    if (events.isEmpty) return const SizedBox.shrink();
    final event = events.first;
    final emoji = LiveGiftCatalog.emojiById[event.giftId] ?? '🎁';
    final jeton = event.jetonAmount;
    final qtyLabel = event.quantity > 1 ? ' x${event.quantity}' : '';
    final imageUrl = event.displayImageUrl;

    return IgnorePointer(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(22),
              gradient: LinearGradient(
                colors: [
                  Colors.black.withValues(alpha: 0.72),
                  const Color(0xFF2A1548).withValues(alpha: 0.88),
                ],
              ),
              border: Border.all(color: Colors.white.withValues(alpha: 0.22)),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFFF4D9D).withValues(alpha: 0.35),
                  blurRadius: 24,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (imageUrl != null)
                    CanlifalNetworkImage(
                      url: imageUrl,
                      width: 48,
                      height: 48,
                      fit: BoxFit.contain,
                      errorWidget:
                          Text(emoji, style: const TextStyle(fontSize: 36)),
                    )
                  else
                    Text(emoji, style: const TextStyle(fontSize: 36)),
                  const SizedBox(width: 12),
                  Flexible(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '👤 ${event.senderName}',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          '🌹 ${event.giftName}$qtyLabel',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFFFF8EC7),
                          ),
                        ),
                        Text(
                          jeton > 0 ? '$jeton Jeton gönderdi' : 'Hediye gönderdi',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: Colors.amber.shade200,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          )
              .animate(key: ValueKey(event.id))
              .fadeIn(duration: 220.ms)
              .scale(
                begin: const Offset(0.85, 0.85),
                end: const Offset(1, 1),
                duration: 280.ms,
                curve: Curves.easeOutBack,
              )
              .then(delay: const Duration(seconds: 3))
              .fadeOut(duration: 500.ms),
        ),
      ),
    );
  }
}
