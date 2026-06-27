import 'package:flutter/material.dart';

import '../../../domain/entities/chat_room_message.dart';
import '../../theme/voice_room_tokens.dart';

/// Son hediye bildirimleri — TikTok Live tarzı kayan şerit.
class VoiceFloatingGiftsStrip extends StatelessWidget {
  const VoiceFloatingGiftsStrip({
    super.key,
    required this.messages,
    this.maxItems = 2,
  });

  final List<ChatRoomMessage> messages;
  final int maxItems;

  @override
  Widget build(BuildContext context) {
    final gifts = messages
        .where((m) => m.kind == ChatMessageKind.gift)
        .toList()
        .reversed
        .take(maxItems)
        .toList();
    if (gifts.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final g in gifts)
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: _GiftBanner(message: g),
          ),
      ],
    );
  }
}

class _GiftBanner extends StatelessWidget {
  const _GiftBanner({required this.message});

  final ChatRoomMessage message;

  @override
  Widget build(BuildContext context) {
    final emoji = message.giftEmoji ?? '🎁';
    final count = message.giftCount ?? 1;
    final who = message.user?.displayName ?? 'Biri';

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 420),
      curve: Curves.easeOutCubic,
      builder: (context, t, child) {
        return Opacity(
          opacity: t,
          child: Transform.translate(
            offset: Offset((1 - t) * 24, 0),
            child: child,
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              VoiceRoomTokens.neonPink.withValues(alpha: 0.35),
              VoiceRoomTokens.gold.withValues(alpha: 0.25),
            ],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: VoiceRoomTokens.gold.withValues(alpha: 0.45)),
          boxShadow: VoiceRoomTokens.goldGlow(blur: 12),
        ),
        child: Row(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 28)),
            const SizedBox(width: 10),
            Expanded(
              child: RichText(
                text: TextSpan(
                  style: const TextStyle(fontSize: 12, color: Colors.white),
                  children: [
                    TextSpan(
                      text: who,
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        color: VoiceRoomTokens.gold,
                      ),
                    ),
                    TextSpan(text: ' ${message.content}'),
                  ],
                ),
              ),
            ),
            Text(
              'x$count',
              style: const TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 18,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
