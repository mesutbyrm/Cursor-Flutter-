import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../domain/cosmetic_effect_kind.dart';

/// Avatar etrafında parçacık efektleri.
class CosmeticParticleOverlay extends StatelessWidget {
  const CosmeticParticleOverlay({
    super.key,
    required this.kind,
    required this.size,
    required this.controller,
  });

  final CosmeticEffectKind kind;
  final double size;
  final Animation<double> controller;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        return CustomPaint(
          size: Size.square(size),
          painter: _ParticlePainter(
            kind: kind,
            progress: controller.value,
          ),
        );
      },
    );
  }
}

class _ParticlePainter extends CustomPainter {
  _ParticlePainter({required this.kind, required this.progress});

  final CosmeticEffectKind kind;
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final r = size.shortestSide / 2;
    final paint = Paint()..style = PaintingStyle.fill;
    final count = switch (kind) {
      CosmeticEffectKind.particleGalaxy => 16,
      CosmeticEffectKind.particleGoldDust => 14,
      CosmeticEffectKind.particleDiamonds => 10,
      _ => 8,
    };
    final color = switch (kind) {
      CosmeticEffectKind.particleHearts => const Color(0xFFFF4081),
      CosmeticEffectKind.particleSnow => Colors.white70,
      CosmeticEffectKind.particleRoses => const Color(0xFFE91E63),
      CosmeticEffectKind.particleGoldDust => const Color(0xFFFFD54F),
      CosmeticEffectKind.particleDiamonds => const Color(0xFF00D2FF),
      CosmeticEffectKind.particleGalaxy => const Color(0xFFB388FF),
      _ => Colors.white60,
    };
    paint.color = color;
    for (var i = 0; i < count; i++) {
      final a = progress * math.pi * 2 + (i / count) * math.pi * 2;
      final dist = r + 4 + (i % 3) * 3;
      final p = center + Offset(math.cos(a) * dist, math.sin(a) * dist);
      canvas.drawCircle(p, 1.8 + (i % 2), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _ParticlePainter old) =>
      old.progress != progress || old.kind != kind;
}
