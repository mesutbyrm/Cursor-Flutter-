import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../live/domain/entities/live_gift_catalog.dart';
import '../../providers/voice_seat_gift_flash_provider.dart';

/// Sesli oda koltuk altı hediye flaşı — en fazla 3, her biri 3 sn.
class VoiceSeatGiftFlashStack extends ConsumerWidget {
  const VoiceSeatGiftFlashStack({
    super.key,
    required this.roomKey,
    this.userId,
    this.displayName,
  });

  final String roomKey;
  final String? userId;
  final String? displayName;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final signature = ref.watch(
      voiceSeatGiftFlashProvider(roomKey).select(
        (list) => VoiceSeatGiftFlashNotifier.flashSignature(
          list,
          userId: userId,
          displayName: displayName,
        ),
      ),
    );
    if (signature.isEmpty) return const SizedBox.shrink();

    final flashes = VoiceSeatGiftFlashNotifier.flashesForReceiver(
      ref.read(voiceSeatGiftFlashProvider(roomKey)),
      userId: userId,
      displayName: displayName,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final f in flashes)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: _FlashRow(flash: f),
          ),
      ],
    );
  }
}

class _FlashRow extends StatelessWidget {
  const _FlashRow({required this.flash});

  final VoiceSeatGiftFlash flash;

  @override
  Widget build(BuildContext context) {
    final emoji = LiveGiftCatalog.emojiById[flash.giftName] ?? '🎁';
    final qty = flash.quantity > 1 ? ' x${flash.quantity}' : '';

    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white24),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(emoji, style: const TextStyle(fontSize: 12)),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(
                    '${flash.senderName} → ${flash.giftName}$qty',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
            if (flash.jeton > 0)
              Text(
                '${flash.jeton} Jeton',
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  color: Colors.amber.shade200,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
