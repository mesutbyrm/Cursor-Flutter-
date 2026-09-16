import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../gifts/providers/live_gift_providers.dart';

/// Son hediye bildirimleri — sol video altı (gerçek gift event).
class LivePkGiftToastOverlay extends ConsumerWidget {
  const LivePkGiftToastOverlay({super.key, this.bottomInset = 120});

  final double bottomInset;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ctrl = ref.watch(liveGiftControllerProvider);
    if (ctrl.notifications.isEmpty) return const SizedBox.shrink();
    final tail = ctrl.notifications.length > 2
        ? ctrl.notifications.sublist(ctrl.notifications.length - 2)
        : ctrl.notifications;

    return Positioned(
      left: 10,
      bottom: bottomInset,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final e in tail)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.58),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: const Color(0xFFFF2D7A).withValues(alpha: 0.35),
                  ),
                ),
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        e.senderName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 11,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '${e.giftName} x${e.quantity}',
                        style: const TextStyle(
                          color: Color(0xFFFFD54F),
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
