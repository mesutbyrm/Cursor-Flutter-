import 'package:flutter/material.dart';

import '../../domain/entities/live_gift_event.dart';

/// Canlı yayın — son 3 hediye atan (jeton miktarı ile); herkes görür.
class LiveRecentGiftersBox extends StatelessWidget {
  const LiveRecentGiftersBox({super.key, required this.notifications});

  final List<LiveGiftEvent> notifications;

  @override
  Widget build(BuildContext context) {
    final recent = <LiveGiftEvent>[];
    final seen = <String>{};
    for (final e in notifications) {
      final key = (e.senderId ?? e.senderName).trim();
      if (key.isEmpty || !seen.add(key)) continue;
      recent.add(e);
      if (recent.length >= 3) break;
    }
    if (recent.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.55),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFFFD54F).withValues(alpha: 0.45)),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Row(
                children: [
                  Icon(Icons.card_giftcard_rounded,
                      size: 14, color: Color(0xFFFFD54F)),
                  SizedBox(width: 4),
                  Text(
                    'Son hediyeler',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              for (final e in recent)
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Text.rich(
                    TextSpan(
                      style: const TextStyle(
                        fontSize: 10,
                        color: Colors.white,
                        height: 1.25,
                      ),
                      children: [
                        TextSpan(
                          text: e.senderName,
                          style: const TextStyle(
                            fontWeight: FontWeight.w900,
                            color: Color(0xFFFFD54F),
                          ),
                        ),
                        TextSpan(
                          text: ' — ${e.jetonAmount} jeton attı',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: Colors.white.withValues(alpha: 0.85),
                          ),
                        ),
                      ],
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
