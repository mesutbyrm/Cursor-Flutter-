import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../gifts/providers/live_gift_providers.dart';

/// Pane içi hediye bildirimi — referans: avatar + isim + hediye + adet.
class LivePkPaneGiftToast extends ConsumerWidget {
  const LivePkPaneGiftToast({
    super.key,
    required this.hostUserId,
    required this.hostLabel,
    this.alignLeft = true,
  });

  final String? hostUserId;
  final String hostLabel;
  final bool alignLeft;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ctrl = ref.watch(liveGiftControllerProvider);
    if (ctrl.notifications.isEmpty) return const SizedBox.shrink();

    final uid = hostUserId?.trim() ?? '';
    final label = hostLabel.trim().toLowerCase();
    final filtered = ctrl.notifications.where((e) {
      if (uid.isNotEmpty && e.receiverId?.trim() == uid) return true;
      final recv = e.receiverName.trim().toLowerCase();
      if (label.isNotEmpty && recv == label) return true;
      if (label.isNotEmpty && recv.contains(label)) return true;
      return false;
    }).toList();
    if (filtered.isEmpty) return const SizedBox.shrink();

    final tail = filtered.length > 3
        ? filtered.sublist(filtered.length - 3)
        : filtered;

    return Align(
      alignment: alignLeft ? Alignment.bottomLeft : Alignment.bottomLeft,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(6, 0, 6, 52),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final e in tail)
              Padding(
                padding: const EdgeInsets.only(bottom: 5),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.55),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircleAvatar(
                          radius: 10,
                          backgroundColor:
                              const Color(0xFF7C3AED).withValues(alpha: 0.6),
                          child: Text(
                            e.senderName.isNotEmpty
                                ? e.senderName[0].toUpperCase()
                                : '?',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 9,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Flexible(
                          child: RichText(
                            text: TextSpan(
                              style: const TextStyle(fontSize: 10, height: 1.2),
                              children: [
                                TextSpan(
                                  text: '${e.senderName} ',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                TextSpan(
                                  text: '${e.giftName} ',
                                  style: const TextStyle(
                                    color: Color(0xFFFFD54F),
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                TextSpan(
                                  text: 'x${e.quantity}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
