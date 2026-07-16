import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:canlifal_social/core/images/canlifal_network_image.dart';

import '../../../domain/entities/live_gift_catalog.dart';
import '../providers/live_seat_gift_flash_provider.dart';

/// Koltuk altı hediye flaşı — 3 sn sıralı liste.
class LiveSeatGiftFlashStack extends ConsumerWidget {
  const LiveSeatGiftFlashStack({
    super.key,
    this.userId,
    this.displayName,
  });

  final String? userId;
  final String? displayName;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(liveSeatGiftFlashProvider);
    final flashes = ref
        .read(liveSeatGiftFlashProvider.notifier)
        .forReceiver(userId: userId, displayName: displayName);
    if (flashes.isEmpty) return const SizedBox.shrink();

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

  final LiveSeatGiftFlash flash;

  @override
  Widget build(BuildContext context) {
    final emoji = LiveGiftCatalog.emojiById[flash.giftName] ?? '🎁';
    final qty = flash.quantity > 1 ? ' x${flash.quantity}' : '';
    final jeton = flash.jeton;

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
                if (flash.imageUrl != null)
                  CanlifalNetworkImage(
                    url: flash.imageUrl!,
                    width: 18,
                    height: 18,
                    fit: BoxFit.contain,
                    errorWidget: Text(emoji, style: const TextStyle(fontSize: 14)),
                  )
                else
                  Text(emoji, style: const TextStyle(fontSize: 14)),
                const SizedBox(width: 4),
                Text(
                  '${flash.giftName}$qty',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
            if (jeton > 0)
              Text(
                '$jeton Jeton',
                style: TextStyle(
                  fontSize: 10,
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
