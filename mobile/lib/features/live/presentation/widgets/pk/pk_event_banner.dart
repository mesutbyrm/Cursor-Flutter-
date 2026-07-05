import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/pk_room_providers.dart';

/// Aktif premium etkinlik (çarpan) banner'ı — renkli nabız + geri sayım.
class PkEventBanner extends ConsumerWidget {
  const PkEventBanner({super.key, required this.matchId});

  final String matchId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final event = ref.watch(pkActiveEventProvider(matchId));
    if (event == null || !event.isLive) return const SizedBox.shrink();

    final c = event.type.color;
    Widget banner = Container(
      margin: const EdgeInsets.fromLTRB(10, 2, 10, 2),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [c.withValues(alpha: 0.55), c.withValues(alpha: 0.22)],
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: c, width: 1.5),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(event.type.emoji, style: const TextStyle(fontSize: 16)),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              '${event.type.label}  ×${event.multiplier}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
                fontSize: 13,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              '${event.remainingSec}s',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );

    // Hafif nabız — dikkat çeker.
    banner = TweenAnimationBuilder<double>(
      key: ValueKey(event.remainingSec),
      tween: Tween(begin: 1.0, end: 1.03),
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeInOut,
      builder: (_, s, child) => Transform.scale(scale: s, child: child),
      child: banner,
    );
    return banner;
  }
}
