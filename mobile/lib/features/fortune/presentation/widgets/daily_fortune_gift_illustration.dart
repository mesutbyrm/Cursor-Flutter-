import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Günlük fal açılış — mor hediye kutusu + altın kurdele (mockup).
class DailyFortuneGiftIllustration extends StatelessWidget {
  const DailyFortuneGiftIllustration({super.key, this.height = 200});

  final double height;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      width: height * 0.85,
      child: CustomPaint(
        painter: _GiftPainter(),
        child: const SizedBox.expand(),
      ),
    );
  }
}

class _GiftPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final cx = w * 0.5;
    final boxTop = h * 0.28;
    final boxH = h * 0.48;
    final boxW = w * 0.62;

    // Arka ay ve yıldızlar
    _drawMoon(canvas, Offset(w * 0.18, h * 0.18));
    _drawMoon(canvas, Offset(w * 0.82, h * 0.22), small: true);
    final dot = Paint()..color = Colors.white.withValues(alpha: 0.4);
    for (final p in [
      Offset(w * 0.1, h * 0.35),
      Offset(w * 0.9, h * 0.4),
      Offset(w * 0.75, h * 0.12),
    ]) {
      canvas.drawCircle(p, 1.2, dot);
    }

    // Kutu gölge
    final boxRect = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(cx, boxTop + boxH / 2),
        width: boxW,
        height: boxH,
      ),
      const Radius.circular(10),
    );
    canvas.drawRRect(
      boxRect.shift(const Offset(3, 5)),
      Paint()..color = Colors.black.withValues(alpha: 0.4),
    );

    // Kutu gövde
    canvas.drawRRect(
      boxRect,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF9333EA), Color(0xFF5B21B6), Color(0xFF3B0764)],
        ).createShader(boxRect.outerRect),
    );

    // İç parıltı
    canvas.drawRRect(
      boxRect,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(0, -0.5),
          radius: 0.9,
          colors: [
            Colors.white.withValues(alpha: 0.25),
            Colors.transparent,
          ],
        ).createShader(boxRect.outerRect),
    );

    // Dikey kurdele
    final ribbonW = boxW * 0.14;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(cx, boxTop + boxH / 2),
          width: ribbonW,
          height: boxH + 8,
        ),
        const Radius.circular(3),
      ),
      Paint()
        ..shader = const LinearGradient(
          colors: [Color(0xFFF5E6C8), Color(0xFFD4AF37), Color(0xFFB8860B)],
        ).createShader(Rect.fromLTWH(cx - ribbonW, boxTop, ribbonW * 2, boxH)),
    );

    // Yatay kurdele
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(cx, boxTop + boxH * 0.42),
          width: boxW + 6,
          height: ribbonW * 0.9,
        ),
        const Radius.circular(3),
      ),
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [Color(0xFFF5E6C8), Color(0xFFD4AF37), Color(0xFFB8860B)],
        ).createShader(Rect.fromLTWH(0, boxTop, w, ribbonW)),
    );

    // Fiyonk
    final bowY = boxTop - h * 0.02;
    for (final side in [-1.0, 1.0]) {
      final path = Path()
        ..moveTo(cx, bowY)
        ..quadraticBezierTo(
          cx + side * w * 0.18,
          bowY - h * 0.08,
          cx + side * w * 0.14,
          bowY + h * 0.04,
        )
        ..quadraticBezierTo(
          cx + side * w * 0.06,
          bowY + h * 0.06,
          cx,
          bowY + h * 0.03,
        )
        ..close();
      canvas.drawPath(
        path,
        Paint()..color = const Color(0xFFE9C46A),
      );
    }
    canvas.drawCircle(
      Offset(cx, bowY + h * 0.01),
      w * 0.04,
      Paint()..color = const Color(0xFFD4AF37),
    );

    // Kenar parıltı
    canvas.drawRRect(
      boxRect,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2
        ..color = const Color(0xFFC084FC).withValues(alpha: 0.6),
    );
  }

  void _drawMoon(Canvas canvas, Offset c, {bool small = false}) {
    final r = small ? 14.0 : 18.0;
    canvas.drawCircle(
      c,
      r,
      Paint()..color = const Color(0xFFC084FC).withValues(alpha: 0.25),
    );
    canvas.drawArc(
      Rect.fromCircle(center: c, radius: r),
      math.pi * 0.2,
      math.pi * 1.2,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5
        ..color = const Color(0xFFE9D5FF).withValues(alpha: 0.5),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
