import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class CosmicBackground extends StatelessWidget {
  const CosmicBackground({super.key});

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        DecoratedBox(
          decoration: BoxDecoration(gradient: AppTheme.cosmicBackdropGradient),
        ),
        CustomPaint(
          painter: _StarfieldPainter(),
          child: const SizedBox.expand(),
        ),
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: const Alignment(0.15, -0.55),
                radius: 0.85,
                colors: [
                  AppTheme.cosmicPurple.withValues(alpha: 0.35),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _StarfieldPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    const count = 160;
    for (var i = 0; i < count; i++) {
      final u = (i * 0.618033988749895) % 1.0;
      final v = (i * 0.381966011250105) % 1.0;
      final x = u * size.width;
      final y = v * size.height;
      final tw = math.sin(i * 2.17) * 0.5 + 0.5;
      final opacity = 0.06 + tw * 0.22;
      final radius = 0.45 + (i % 4) * 0.35;
      canvas.drawCircle(
        Offset(x, y),
        radius,
        Paint()..color = Colors.white.withValues(alpha: opacity),
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
