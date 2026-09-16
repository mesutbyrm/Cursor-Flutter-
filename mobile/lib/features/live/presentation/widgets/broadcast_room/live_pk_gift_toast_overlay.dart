import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../gifts/providers/live_gift_providers.dart';

/// Son hediye bildirimi — referans floating toast.
class LivePkGiftToastOverlay extends ConsumerWidget {
  const LivePkGiftToastOverlay({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ctrl = ref.watch(liveGiftControllerProvider);
    if (ctrl.notifications.isEmpty) return const SizedBox.shrink();
    final e = ctrl.notifications.last;

    return Align(
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.only(left: 12, top: 120),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.62),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFFF2D7A).withValues(alpha: 0.4)),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  e.senderName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  '${e.giftName} x${e.quantity}',
                  style: const TextStyle(color: Color(0xFFFFD54F), fontSize: 12),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
