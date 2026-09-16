import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

/// Hediye/puan artışı — kısa floating +N (mevcut skor akışına bağlı burst token).
class LivePkScorePopOverlay extends StatelessWidget {
  const LivePkScorePopOverlay({
    super.key,
    required this.burstToken,
    required this.delta,
    required this.toLeft,
  });

  final int burstToken;
  final int delta;
  final bool toLeft;

  @override
  Widget build(BuildContext context) {
    if (burstToken <= 0 || delta <= 0) return const SizedBox.shrink();
    final align = toLeft ? Alignment.centerLeft : Alignment.centerRight;
    return Align(
      alignment: align,
      child: Padding(
        padding: EdgeInsets.only(
          left: toLeft ? 24 : 0,
          right: toLeft ? 0 : 24,
          top: MediaQuery.sizeOf(context).height * 0.32,
        ),
        child: Text(
          '+${delta >= 1000 ? '${(delta / 1000).toStringAsFixed(1)}K' : delta}',
          style: const TextStyle(
            color: Color(0xFFFFD54F),
            fontSize: 28,
            fontWeight: FontWeight.w900,
            shadows: [
              Shadow(color: Colors.black87, blurRadius: 8),
            ],
          ),
        )
            .animate(key: ValueKey(burstToken))
            .fadeIn(duration: 120.ms)
            .moveY(begin: 12, end: -36, duration: 900.ms, curve: Curves.easeOut)
            .fadeOut(delay: 600.ms, duration: 300.ms),
      ),
    );
  }
}
