import 'dart:math';

import 'package:flutter/material.dart';

/// PK bittiğinde yalnızca kazanan yarıda konfeti; kaybeden yarı hafif karartma.
class LivePkPaneOutcomeOverlay extends StatelessWidget {
  const LivePkPaneOutcomeOverlay({
    super.key,
    required this.visible,
    required this.winnerPane,
    required this.progress,
  });

  final bool visible;
  final bool winnerPane;
  final double progress;

  @override
  Widget build(BuildContext context) {
    if (!visible || progress <= 0) return const SizedBox.shrink();

    return Stack(
      fit: StackFit.expand,
      children: [
        if (!winnerPane)
          ColoredBox(
            color: Colors.black.withValues(alpha: 0.35 * progress.clamp(0.0, 1.0)),
          ),
        if (winnerPane)
          IgnorePointer(
            child: CustomPaint(
              painter: _PkHalfConfettiPainter(progress: progress),
              size: Size.infinite,
            ),
          ),
      ],
    );
  }
}

class _PkHalfConfettiPainter extends CustomPainter {
  _PkHalfConfettiPainter({required this.progress});

  final double progress;
  final _rng = Random(11);

  @override
  void paint(Canvas canvas, Size size) {
    final t = progress.clamp(0.0, 1.0);
    if (t <= 0) return;
    for (var i = 0; i < 28; i++) {
      final x = _rng.nextDouble() * size.width;
      final y = (t * size.height * 1.15 + i * 14) % size.height;
      final paint = Paint()
        ..color = [
          const Color(0xFFFFD700),
          const Color(0xFFFF2D7A),
          const Color(0xFF448AFF),
        ][_rng.nextInt(3)]
            .withValues(alpha: 0.75 * t);
      canvas.drawRect(
        Rect.fromCenter(center: Offset(x, y), width: 5, height: 9),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _PkHalfConfettiPainter old) =>
      old.progress != progress;
}
