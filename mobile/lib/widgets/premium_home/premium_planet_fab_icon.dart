import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Alt orta FAB — mockup’taki “halkalı gezegen” hissi.
class PremiumPlanetFabIcon extends StatelessWidget {
  const PremiumPlanetFabIcon({super.key, this.size = 30});

  final double size;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size),
      painter: _PlanetRingPainter(),
    );
  }
}

class _PlanetRingPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2);
    final planetR = size.shortestSide * 0.27;

    final ringPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.88)
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.shortestSide * 0.06
      ..strokeCap = StrokeCap.round;

    canvas.save();
    canvas.translate(c.dx, c.dy);
    canvas.rotate(-math.pi / 5);
    canvas.translate(-c.dx, -c.dy);

    final ringRect = Rect.fromCenter(
      center: c,
      width: size.width * 0.9,
      height: size.height * 0.38,
    );
    canvas.drawArc(ringRect, 0.12, math.pi * 1.76, false, ringPaint);
    canvas.restore();

    final body = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    canvas.drawCircle(c, planetR, body);

    final highlight = Paint()
      ..color = Colors.white.withValues(alpha: 0.35)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(c.dx - planetR * 0.25, c.dy - planetR * 0.28), planetR * 0.22, highlight);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
