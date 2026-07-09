import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../domain/entities/live_gift_catalog.dart';
import '../../../domain/entities/live_gift_event.dart';

/// Ortada gösterilen hediye bildirimi — «kullanıcı yayıncıya hediye (jeton) gönderdi».
class GiftCenterToastStack extends StatelessWidget {
  const GiftCenterToastStack({super.key, required this.events});

  final List<LiveGiftEvent> events;

  @override
  Widget build(BuildContext context) {
    if (events.isEmpty) return const SizedBox.shrink();
    final event = events.first;
    final emoji = LiveGiftCatalog.emojiById[event.giftId] ?? '🎁';
    final jeton = event.coinCost * event.quantity;
    final giftLabel =
        event.quantity > 1 ? '${event.quantity}×${event.giftName}' : event.giftName;

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
                  Text(emoji, style: const TextStyle(fontSize: 36)),
                  const SizedBox(width: 12),
                  Flexible(
                    child: RichText(
                      textAlign: TextAlign.center,
                      text: TextSpan(
                        style: const TextStyle(
                          fontSize: 14,
                          height: 1.35,
                          color: Colors.white,
                        ),
                        children: [
                          TextSpan(
                            text: event.senderName,
                            style: const TextStyle(fontWeight: FontWeight.w900),
                          ),
                          const TextSpan(text: ' '),
                          TextSpan(
                            text: event.receiverName,
                            style: TextStyle(
                              fontWeight: FontWeight.w800,
                              color: Colors.cyanAccent.shade100,
                            ),
                          ),
                          const TextSpan(text: '\'a '),
                          TextSpan(
                            text: giftLabel,
                            style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              color: Color(0xFFFF8EC7),
                            ),
                          ),
                          TextSpan(
                            text: ' ($jeton jeton)',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              color: Colors.amber.shade200,
                            ),
                          ),
                          const TextSpan(text: ' gönderdi'),
                        ],
                      ),
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
              ),
        ),
      ),
    );
  }
}
