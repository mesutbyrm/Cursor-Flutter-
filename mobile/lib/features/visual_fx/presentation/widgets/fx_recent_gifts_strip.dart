import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../voice_hub/presentation/theme/voice_room_tokens.dart';
import '../../domain/fx_gift_display_item.dart';
import '../providers/voice_room_gift_display_provider.dart';

/// Koltuk altı — son hediyeler (tek satır, 3 sn rotasyon).
class FxRecentGiftsStrip extends ConsumerWidget {
  const FxRecentGiftsStrip({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final active = ref.watch(
      voiceRoomGiftDisplayProvider.select((s) => s.activeRecent),
    );
    if (active == null) return const SizedBox.shrink();

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 320),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      child: _GiftChip(
        key: ValueKey(active.eventId),
        item: active,
      ),
    );
  }
}

class _GiftChip extends StatelessWidget {
  const _GiftChip({super.key, required this.item});

  final FxGiftDisplayItem item;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 220),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.55),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: VoiceRoomTokens.gold.withValues(alpha: 0.4),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('🎁', style: TextStyle(fontSize: 13)),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  '[${item.senderName} → ${item.receiverName}] ${item.giftName}',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    height: 1.2,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
