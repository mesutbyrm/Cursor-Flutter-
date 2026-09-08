import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/voice_recent_gifts_provider.dart';
import '../../../../../core/economy/presentation/providers/economy_providers.dart';
import '../../theme/voice_room_tokens.dart';

/// Koltukların altı sağ — son 3 hediye atan (jeton miktarı ile).
class VoiceRecentGiftersBox extends ConsumerWidget {
  const VoiceRecentGiftersBox({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gifters = ref.watch(voiceRecentGiftersListProvider).take(3).toList();
    if (gifters.isEmpty) return const SizedBox.shrink();
    final jetonLabel = economyCurrencyLabel(ref, key: 'jeton');

    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          constraints: const BoxConstraints(minWidth: 120, maxWidth: 200),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: VoiceRoomTokens.gold.withValues(alpha: 0.4),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.card_giftcard_rounded,
                    size: 14,
                    color: VoiceRoomTokens.gold.withValues(alpha: 0.9),
                  ),
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
              ...gifters.map((g) => _GifterRow(gifter: g, jetonLabel: jetonLabel)),
            ],
          ),
        ),
      ),
    );
  }
}

class _GifterRow extends StatelessWidget {
  const _GifterRow({required this.gifter, required this.jetonLabel});

  final VoiceRecentGifter gifter;
  final String jetonLabel;

  @override
  Widget build(BuildContext context) {
    final name = gifter.senderName;
    return Padding(
      padding: const EdgeInsets.only(top: 3),
      child: RichText(
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        text: TextSpan(
          style: const TextStyle(fontSize: 10, color: Colors.white, height: 1.25),
          children: [
            TextSpan(
              text: name,
              style: const TextStyle(
                fontWeight: FontWeight.w900,
                color: VoiceRoomTokens.gold,
              ),
            ),
            if ((gifter.receiverName ?? '').isNotEmpty)
              TextSpan(
                text: ' → ${gifter.receiverName}',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: Colors.white.withValues(alpha: 0.9),
                ),
              ),
            TextSpan(
              text: ' — ${gifter.lastJeton} $jetonLabel'
                  '${(gifter.giftName ?? '').isNotEmpty ? ' (${gifter.giftName})' : ''}',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.white.withValues(alpha: 0.85),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
