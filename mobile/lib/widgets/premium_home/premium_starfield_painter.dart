import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Hafif yıldız / toz dokusu.
class PremiumStarfieldPainter extends CustomPainter {
  PremiumStarfieldPainter({this.seed = 42});

  final int seed;

  @override
  void paint(Canvas canvas, Size size) {
    final rnd = math.Random(seed);
    final paint = Paint()..color = Colors.white;
    for (var i = 0; i < 90; i++) {
      final x = rnd.nextDouble() * size.width;
      final y = rnd.nextDouble() * size.height;
      final r = rnd.nextDouble() * 1.2 + 0.3;
      final o = rnd.nextDouble() * 0.35 + 0.08;
      paint.color = Colors.white.withValues(alpha: o);
      canvas.drawCircle(Offset(x, y), r, paint);
    }
  }

  @override
  bool shouldRepaint(covariant PremiumStarfieldPainter oldDelegate) =>
      oldDelegate.seed != seed;
}
