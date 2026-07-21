import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../sync/gift_session_controller.dart';
import '../sync/gift_session_state.dart';

/// Host ve guest aynı widget — Son Hediyeler kutusu (combo: x1, x2, x3).
class UnifiedRecentGiftersBox extends ConsumerWidget {
  const UnifiedRecentGiftersBox({
    super.key,
    required this.sessionKey,
    this.accentColor = const Color(0xFFFFD54F),
  });

  final String sessionKey;
  final Color accentColor;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final items = ref.watch(giftSessionProvider(sessionKey)).recentGifts;
    if (items.isEmpty) return const SizedBox.shrink();

    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          constraints: const BoxConstraints(minWidth: 140, maxWidth: 280),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.55),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: accentColor.withValues(alpha: 0.45)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Icon(Icons.card_giftcard_rounded,
                      size: 14, color: accentColor.withValues(alpha: 0.9)),
                  const SizedBox(width: 4),
                  const Text(
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
              ...items.map((g) => _Row(item: g, accent: accentColor)),
            ],
          ),
        ),
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({required this.item, required this.accent});

  final GiftRecentItem item;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 3),
      child: RichText(
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        text: TextSpan(
          style: const TextStyle(fontSize: 10, color: Colors.white, height: 1.25),
          children: [
            TextSpan(
              text: item.senderName,
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
            const TextSpan(text: ' → '),
            TextSpan(
              text: item.receiverName,
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: accent.withValues(alpha: 0.95),
              ),
            ),
            const TextSpan(text: ': '),
            TextSpan(
              text: item.giftName,
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
            TextSpan(
              text: item.comboLabel,
              style: TextStyle(
                fontWeight: FontWeight.w900,
                color: accent,
              ),
            ),
            TextSpan(
              text: ' · ${item.jetonAmount} jeton',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.white.withValues(alpha: 0.8),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
