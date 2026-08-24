import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../domain/cosmetic_effect_kind.dart';

/// Animasyonlu profil çerçevesi — CustomPainter efektleri.
class CosmeticFramePainter extends CustomPainter {
  CosmeticFramePainter({
    required this.kind,
    required this.progress,
    required this.colors,
  });

  final CosmeticEffectKind kind;
  final double progress;
  final List<Color> colors;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.shortestSide / 2;
    final ring = Paint()..style = PaintingStyle.stroke;

    switch (kind) {
      case CosmeticEffectKind.rotatingLight:
        ring.shader = SweepGradient(
          center: Alignment.center,
          startAngle: progress * math.pi * 2,
          endAngle: progress * math.pi * 2 + math.pi * 2,
          colors: [
            ...colors,
            colors.isNotEmpty ? colors.first : Colors.amber,
          ],
        ).createShader(Rect.fromCircle(center: center, radius: radius));
        ring.strokeWidth = 3.5;
        canvas.drawCircle(center, radius - 2, ring);
        break;
      case CosmeticEffectKind.neonGlow:
        ring
          ..color = colors.isNotEmpty ? colors.first : const Color(0xFFB832FF)
          ..strokeWidth = 3
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
        canvas.drawCircle(center, radius - 2, ring);
        break;
      case CosmeticEffectKind.fire:
        ring.shader = SweepGradient(
          center: Alignment.center,
          startAngle: progress * math.pi * 2,
          endAngle: progress * math.pi * 2 + math.pi * 2,
          colors: const [
            Color(0xFFFF5722),
            Color(0xFFFFD54F),
            Color(0xFFFF5722),
          ],
        ).createShader(Rect.fromCircle(center: center, radius: radius));
        ring.strokeWidth = 4;
        canvas.drawCircle(center, radius - 2, ring);
        break;
      case CosmeticEffectKind.goldParticles:
        ring
          ..color = const Color(0xFFFFD54F)
          ..strokeWidth = 3.5;
        canvas.drawCircle(center, radius - 2, ring);
        _drawOrbitDots(canvas, center, radius, 8, const Color(0xFFFFD54F));
        break;
      case CosmeticEffectKind.diamond:
        ring
          ..color = const Color(0xFF00D2FF)
          ..strokeWidth = 3;
        canvas.drawCircle(center, radius - 2, ring);
        break;
      case CosmeticEffectKind.cosmicStars:
        ring
          ..color = const Color(0xFF7C4DFF)
          ..strokeWidth = 2.5;
        canvas.drawCircle(center, radius - 2, ring);
        _drawOrbitDots(canvas, center, radius, 12, Colors.white70);
        break;
      case CosmeticEffectKind.aura:
        ring
          ..color = const Color(0xFF64B5F6).withValues(alpha: 0.7)
          ..strokeWidth = 6
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
        canvas.drawCircle(center, radius - 4, ring);
        break;
      case CosmeticEffectKind.heart:
        ring
          ..color = const Color(0xFFFF4081)
          ..strokeWidth = 3;
        canvas.drawCircle(center, radius - 2, ring);
        break;
      case CosmeticEffectKind.lightning:
        ring
          ..color = const Color(0xFFFFEB3B)
          ..strokeWidth = 3.5;
        canvas.drawCircle(center, radius - 2, ring);
        break;
      case CosmeticEffectKind.rainbow:
        ring.shader = SweepGradient(
          center: Alignment.center,
          startAngle: progress * math.pi * 2,
          endAngle: progress * math.pi * 2 + math.pi * 2,
          colors: const [
            Colors.red,
            Colors.orange,
            Colors.yellow,
            Colors.green,
            Colors.blue,
            Colors.purple,
            Colors.red,
          ],
        ).createShader(Rect.fromCircle(center: center, radius: radius));
        ring.strokeWidth = 3.5;
        canvas.drawCircle(center, radius - 2, ring);
        break;
      case CosmeticEffectKind.crown:
        ring
          ..color = const Color(0xFFFFD700)
          ..strokeWidth = 4;
        canvas.drawCircle(center, radius - 2, ring);
        break;
      default:
        ring
          ..color = colors.isNotEmpty ? colors.first : Colors.white24
          ..strokeWidth = 2;
        canvas.drawCircle(center, radius - 2, ring);
    }
  }

  void _drawOrbitDots(
    Canvas canvas,
    Offset center,
    double radius,
    int count,
    Color color,
  ) {
    final dot = Paint()..color = color;
    for (var i = 0; i < count; i++) {
      final a = progress * math.pi * 2 + (i / count) * math.pi * 2;
      final p = center +
          Offset(math.cos(a) * (radius - 6), math.sin(a) * (radius - 6));
      canvas.drawCircle(p, 2.2, dot);
    }
  }

  @override
  bool shouldRepaint(covariant CosmeticFramePainter old) =>
      old.progress != progress || old.kind != kind;
}
