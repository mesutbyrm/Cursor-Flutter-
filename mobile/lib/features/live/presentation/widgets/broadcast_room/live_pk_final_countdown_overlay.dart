import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

/// Son 10 saniye — FINAL + büyük sayı (timer widget ile senkron).
class LivePkFinalCountdownOverlay extends StatelessWidget {
  const LivePkFinalCountdownOverlay({
    super.key,
    required this.secondsLeft,
    required this.active,
  });

  final int secondsLeft;
  final bool active;

  @override
  Widget build(BuildContext context) {
    if (!active || secondsLeft > 10 || secondsLeft <= 0) {
      return const SizedBox.shrink();
    }
    return IgnorePointer(
      child: Align(
        alignment: const Alignment(0, -0.15),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'SON SANİYELER',
              style: TextStyle(
                color: const Color(0xFFFF6B6B).withValues(alpha: 0.95),
                fontWeight: FontWeight.w900,
                fontSize: 12,
                letterSpacing: 1.2,
              ),
            )
                .animate(onPlay: (c) => c.repeat(reverse: true))
                .fadeIn(duration: 400.ms)
                .shimmer(duration: 1200.ms, color: Colors.white24),
            const SizedBox(height: 6),
            Text(
              '$secondsLeft',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 56,
                fontWeight: FontWeight.w900,
                shadows: [
                  Shadow(color: Color(0xFFFF2D7A), blurRadius: 24),
                ],
              ),
            ).animate(key: ValueKey(secondsLeft)).scale(
                  begin: const Offset(1.15, 1.15),
                  end: const Offset(1, 1),
                  duration: 280.ms,
                  curve: Curves.easeOut,
                ),
          ],
        ),
      ),
    );
  }
}
