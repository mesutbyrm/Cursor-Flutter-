import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Hero sağ — kristal küre + mum (mockup 3D illüstrasyon yerine vektör).
class FortuneHubCrystalIllustration extends StatelessWidget {
  const FortuneHubCrystalIllustration({super.key, this.height = 130});

  final double height;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: height * 0.95,
      height: height,
      child: CustomPaint(
        painter: _CrystalPainter(),
        child: const SizedBox.expand(),
      ),
    );
  }
}

class _CrystalPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final ballCenter = Offset(w * 0.42, h * 0.42);
    final ballR = w * 0.34;

    // Mum ışığı
    final glow = Paint()
      ..shader = RadialGradient(
        colors: [
          const Color(0xFFFFB347).withValues(alpha: 0.35),
          Colors.transparent,
        ],
      ).createShader(Rect.fromCircle(center: Offset(w * 0.78, h * 0.55), radius: w * 0.4));
    canvas.drawCircle(Offset(w * 0.78, h * 0.55), w * 0.38, glow);

    // Kaide
    final baseRect = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(ballCenter.dx, h * 0.82),
        width: w * 0.5,
        height: h * 0.14,
      ),
      const Radius.circular(6),
    );
    canvas.drawRRect(
      baseRect,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF3D2A5C), Color(0xFF1A0B2E)],
        ).createShader(baseRect.outerRect),
    );

    // Küre gölge
    canvas.drawCircle(
      ballCenter.translate(2, 4),
      ballR,
      Paint()..color = Colors.black.withValues(alpha: 0.45),
    );

    // Küre cam
    final ballPaint = Paint()
      ..shader = RadialGradient(
        center: const Alignment(-0.35, -0.4),
        radius: 1.1,
        colors: [
          const Color(0xFFEDE9FE).withValues(alpha: 0.95),
          const Color(0xFFA855F7).withValues(alpha: 0.85),
          const Color(0xFF4C1D95).withValues(alpha: 0.95),
          const Color(0xFF1E1033),
        ],
        stops: const [0.0, 0.35, 0.72, 1.0],
      ).createShader(Rect.fromCircle(center: ballCenter, radius: ballR));
    canvas.drawCircle(ballCenter, ballR, ballPaint);

    // Yansıma
    canvas.drawOval(
      Rect.fromCenter(
        center: ballCenter.translate(-ballR * 0.35, -ballR * 0.38),
        width: ballR * 0.45,
        height: ballR * 0.28,
      ),
      Paint()..color = Colors.white.withValues(alpha: 0.35),
    );

    // Takımyıldızı noktaları
    final starPaint = Paint()..color = const Color(0xFFE9D5FF).withValues(alpha: 0.9);
    for (var i = 0; i < 5; i++) {
      final a = i * math.pi * 2 / 5 - math.pi / 2;
      final p = ballCenter +
          Offset(math.cos(a) * ballR * 0.35, math.sin(a) * ballR * 0.28);
      canvas.drawCircle(p, 1.8, starPaint);
    }

    // Kenar parıltı
    canvas.drawCircle(
      ballCenter,
      ballR,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5
        ..color = const Color(0xFFC084FC).withValues(alpha: 0.55),
    );

    // Mum
    final candleX = w * 0.78;
    final candleBase = h * 0.88;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(candleX, candleBase - h * 0.08),
          width: w * 0.09,
          height: h * 0.22,
        ),
        const Radius.circular(3),
      ),
      Paint()..color = const Color(0xFFF5E6C8),
    );
    // Alev
    final flamePath = Path()
      ..moveTo(candleX, candleBase - h * 0.22)
      ..quadraticBezierTo(
        candleX - w * 0.04,
        candleBase - h * 0.28,
        candleX,
        candleBase - h * 0.32,
      )
      ..quadraticBezierTo(
        candleX + w * 0.04,
        candleBase - h * 0.28,
        candleX,
        candleBase - h * 0.22,
      )
      ..close();
    canvas.drawPath(
      flamePath,
      Paint()
        ..shader = const RadialGradient(
          colors: [Color(0xFFFFF3C4), Color(0xFFFFB347), Color(0xFFFF6B35)],
        ).createShader(Rect.fromLTWH(candleX - 8, candleBase - h * 0.35, 16, 20)),
    );

    // Arka yıldızlar
    final dot = Paint()..color = Colors.white.withValues(alpha: 0.35);
    canvas.drawCircle(Offset(w * 0.15, h * 0.2), 1.2, dot);
    canvas.drawCircle(Offset(w * 0.88, h * 0.15), 1.5, dot);
    canvas.drawCircle(Offset(w * 0.7, h * 0.08), 1, dot);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
