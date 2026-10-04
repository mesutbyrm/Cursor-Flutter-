import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/entities/live_gift_event.dart';
import '../../gifts/providers/live_gift_providers.dart';

/// Son hediye bildirimleri — sol video altı (gerçek gift event).
///
/// Her bildirim [displaySeconds] sn gösterilir, sonra kaybolur (kalıcı kalmaz).
class LivePkGiftToastOverlay extends ConsumerStatefulWidget {
  const LivePkGiftToastOverlay({super.key, this.bottomInset = 120});

  final double bottomInset;
  static const displaySeconds = 5;

  @override
  ConsumerState<LivePkGiftToastOverlay> createState() =>
      _LivePkGiftToastOverlayState();
}

class _LivePkGiftToastOverlayState
    extends ConsumerState<LivePkGiftToastOverlay> {
  Timer? _tick;
  final _seen = <String, DateTime>{};

  @override
  void initState() {
    super.initState();
    _tick = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _tick?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ctrl = ref.watch(liveGiftControllerProvider);
    final now = DateTime.now();
    final fresh = <LiveGiftEvent>[
      for (final e in ctrl.notifications)
        if (now.difference(_seen.putIfAbsent(e.id, () => now)).inSeconds <
            LivePkGiftToastOverlay.displaySeconds)
          e,
    ];
    if (fresh.isEmpty) return const SizedBox.shrink();
    final tail =
        fresh.length > 2 ? fresh.sublist(fresh.length - 2) : fresh;

    return Positioned(
      left: 10,
      bottom: widget.bottomInset,
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
