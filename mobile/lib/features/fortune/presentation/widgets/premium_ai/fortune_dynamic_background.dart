import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../domain/entities/fortune_type_entity.dart';

/// Fal türüne özel hafif animasyonlu kozmik arka plan.
class FortuneDynamicBackground extends StatefulWidget {
  const FortuneDynamicBackground({
    super.key,
    required this.type,
    this.child,
  });

  final FortuneTypeEntity type;
  final Widget? child;

  @override
  State<FortuneDynamicBackground> createState() => _FortuneDynamicBackgroundState();
}

class _FortuneDynamicBackgroundState extends State<FortuneDynamicBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _drift;

  @override
  void initState() {
    super.initState();
    _drift = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 18),
    )..repeat();
  }

  @override
  void dispose() {
    _drift.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: _drift,
        builder: (_, child) {
          return CustomPaint(
            painter: _CosmicPainter(
              accent: widget.type.accent,
              slug: widget.type.slug,
              t: _drift.value,
            ),
            child: child,
          );
        },
        child: widget.child,
      ),
    );
  }
}

class _CosmicPainter extends CustomPainter {
  _CosmicPainter({
    required this.accent,
    required this.slug,
    required this.t,
  });

  final Color accent;
  final String slug;
  final double t;

  @override
  void paint(Canvas canvas, Size size) {
    final base = switch (slug) {
      'tarot' || 'melek-kartlari' => const [Color(0xFF1A0F2E), Color(0xFF0A0118)],
      'kahve-fali' || 'cin-fali' => const [Color(0xFF2A1508), Color(0xFF0A0118)],
      'el-fali' => const [Color(0xFF142A18), Color(0xFF0A0118)],
      'numeroloji' => const [Color(0xFF1A1808), Color(0xFF0A0118)],
      'ruya-tabiri' || 'pendul' || 'istihare' => const [Color(0xFF10183A), Color(0xFF0A0118)],
      'yildiz-haritasi' => const [Color(0xFF0C1A3A), Color(0xFF050210)],
      'ask-fali' || 'katina' => const [Color(0xFF2A0A20), Color(0xFF0A0118)],
      'runik' || 'aura' => const [Color(0xFF181028), Color(0xFF0A0118)],
      'evet-hayir' => const [Color(0xFF1A1608), Color(0xFF0A0118)],
      _ => [accent.withValues(alpha: 0.35), const Color(0xFF0A0118)],
    };

    canvas.drawRect(
      Offset.zero & size,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: base,
        ).createShader(Offset.zero & size),
    );

    final rng = math.Random(slug.hashCode);
    final particlePaint = Paint()..color = accent.withValues(alpha: 0.12);
    for (var i = 0; i < 24; i++) {
      final bx = rng.nextDouble();
      final by = rng.nextDouble();
      final drift = math.sin(t * math.pi * 2 + i) * 6;
      canvas.drawCircle(
        Offset(bx * size.width + drift, by * size.height - drift * 0.5),
        1 + rng.nextDouble() * 1.8,
        particlePaint,
      );
    }

    // Kozmik ışık huzmesi
    final beamX = size.width * (0.2 + 0.6 * t);
    canvas.drawRect(
      Rect.fromLTWH(beamX - 40, 0, 80, size.height),
      Paint()
        ..shader = LinearGradient(
          colors: [
            Colors.transparent,
            accent.withValues(alpha: 0.08),
            Colors.transparent,
          ],
        ).createShader(Rect.fromLTWH(beamX - 40, 0, 80, size.height)),
    );
  }

  @override
  bool shouldRepaint(covariant _CosmicPainter old) => old.t != t;
}
