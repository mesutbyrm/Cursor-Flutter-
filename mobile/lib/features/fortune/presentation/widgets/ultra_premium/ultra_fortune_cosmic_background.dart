import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';

import 'ultra_fortune_tokens.dart';

/// Katmanlı kozmik evren — nebula, yıldızlar, sis, parallax partiküller.
class UltraFortuneCosmicBackground extends StatefulWidget {
  const UltraFortuneCosmicBackground({
    super.key,
    required this.child,
    this.scrollOffset = 0,
  });

  final Widget child;
  final double scrollOffset;

  @override
  State<UltraFortuneCosmicBackground> createState() =>
      _UltraFortuneCosmicBackgroundState();
}

class _UltraFortuneCosmicBackgroundState extends State<UltraFortuneCosmicBackground>
    with TickerProviderStateMixin {
  late final AnimationController _nebula;
  late final AnimationController _particles;
  late final AnimationController _fog;

  @override
  void initState() {
    super.initState();
    _nebula = AnimationController(
      vsync: this,
      duration: UltraFortuneTokens.nebulaBreath,
    )..repeat(reverse: true);
    _particles = AnimationController(
      vsync: this,
      duration: UltraFortuneTokens.particleLoop,
    )..repeat();
    _fog = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 18),
    )..repeat();
  }

  @override
  void dispose() {
    _nebula.dispose();
    _particles.dispose();
    _fog.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final parallax = widget.scrollOffset;

    return Stack(
      fit: StackFit.expand,
      children: [
        const DecoratedBox(
          decoration: BoxDecoration(gradient: UltraFortuneTokens.deepSpaceGradient),
        ),
        AnimatedBuilder(
          animation: _nebula,
          builder: (_, __) => CustomPaint(
            painter: _NebulaPainter(breath: _nebula.value, scrollY: parallax * 0.15),
            size: size,
          ),
        ),
        Transform.translate(
          offset: Offset(0, -parallax * 0.08),
          child: CustomPaint(
            painter: _StarFieldPainter(
              seed: 42,
              density: 1.0,
              twinklePhase: _particles.value,
            ),
            size: size,
          ),
        ),
        AnimatedBuilder(
          animation: _fog,
          builder: (_, __) => CustomPaint(
            painter: _FogPainter(phase: _fog.value, scrollY: parallax * 0.25),
            size: size,
          ),
        ),
        AnimatedBuilder(
          animation: _particles,
          builder: (_, __) => CustomPaint(
            painter: _CosmicParticlePainter(
              progress: _particles.value,
              scrollY: parallax * 0.35,
            ),
            size: size,
          ),
        ),
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: const Alignment(0, -0.2),
              radius: 1.2,
              colors: [
                Colors.transparent,
                UltraFortuneTokens.deepNight.withValues(alpha: 0.35),
                Colors.black.withValues(alpha: 0.65),
              ],
              stops: const [0.35, 0.72, 1.0],
            ),
          ),
        ),
        widget.child,
      ],
    );
  }
}

class _NebulaPainter extends CustomPainter {
  _NebulaPainter({required this.breath, required this.scrollY});

  final double breath;
  final double scrollY;

  @override
  void paint(Canvas canvas, Size size) {
    final pulse = 0.85 + breath * 0.15;

    void drawNebula(Offset center, double radius, List<Color> colors) {
      final paint = Paint()
        ..shader = RadialGradient(
          colors: colors,
          stops: const [0.0, 0.45, 1.0],
        ).createShader(Rect.fromCircle(center: center, radius: radius * pulse));
      canvas.drawCircle(center, radius * pulse, paint);
    }

    drawNebula(
      Offset(size.width * 0.72, size.height * 0.18 - scrollY),
      size.width * 0.55,
      [
        UltraFortuneTokens.electricPurple.withValues(alpha: 0.22),
        UltraFortuneTokens.softLilac.withValues(alpha: 0.12),
        Colors.transparent,
      ],
    );
    drawNebula(
      Offset(size.width * 0.12, size.height * 0.42 - scrollY * 0.6),
      size.width * 0.48,
      [
        const Color(0xFF4C1D95).withValues(alpha: 0.18),
        const Color(0xFF312E81).withValues(alpha: 0.1),
        Colors.transparent,
      ],
    );
    drawNebula(
      Offset(size.width * 0.88, size.height * 0.68 - scrollY * 0.4),
      size.width * 0.38,
      [
        UltraFortuneTokens.softLilac.withValues(alpha: 0.14),
        const Color(0xFF6366F1).withValues(alpha: 0.08),
        Colors.transparent,
      ],
    );
  }

  @override
  bool shouldRepaint(covariant _NebulaPainter old) =>
      old.breath != breath || old.scrollY != scrollY;
}

class _StarFieldPainter extends CustomPainter {
  _StarFieldPainter({
    required this.seed,
    required this.density,
    this.twinklePhase = 0,
  });

  final int seed;
  final double density;
  final double twinklePhase;

  @override
  void paint(Canvas canvas, Size size) {
    final rnd = math.Random(seed);
    final count = (size.width * size.height * 0.00035 * density).round().clamp(180, 900);

    for (var i = 0; i < count; i++) {
      final x = rnd.nextDouble() * size.width;
      final y = rnd.nextDouble() * size.height;
      final base = rnd.nextDouble();
      final twinkle = 0.35 +
          0.65 *
              (0.5 +
                  0.5 *
                      math.sin((twinklePhase + base) * math.pi * 2 + i * 0.3));
      final r = 0.4 + rnd.nextDouble() * 1.6;
      final paint = Paint()
        ..color = Colors.white.withValues(alpha: 0.12 + base * 0.55 * twinkle);
      canvas.drawCircle(Offset(x, y), r, paint);
      if (base > 0.88) {
        canvas.drawCircle(
          Offset(x, y),
          r * 2.5,
          Paint()
            ..color = UltraFortuneTokens.softLilac.withValues(alpha: 0.12 * twinkle)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _StarFieldPainter old) =>
      old.twinklePhase != twinklePhase;
}

class _FogPainter extends CustomPainter {
  _FogPainter({required this.phase, required this.scrollY});

  final double phase;
  final double scrollY;

  @override
  void paint(Canvas canvas, Size size) {
    final drift = phase * size.width;
    final paint = Paint()
      ..shader = LinearGradient(
        begin: Alignment(-1 + phase * 2, 0.3),
        end: Alignment(1 + phase, 0.8),
        colors: [
          Colors.white.withValues(alpha: 0.0),
          Colors.white.withValues(alpha: 0.04),
          UltraFortuneTokens.softLilac.withValues(alpha: 0.06),
          Colors.white.withValues(alpha: 0.0),
        ],
      ).createShader(Rect.fromLTWH(-drift, scrollY, size.width * 2, size.height));

    canvas.drawRect(
      Rect.fromLTWH(-drift, size.height * 0.55 + scrollY * 0.2, size.width * 2, size.height * 0.5),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant _FogPainter old) =>
      old.phase != phase || old.scrollY != scrollY;
}

class _CosmicParticlePainter extends CustomPainter {
  _CosmicParticlePainter({required this.progress, required this.scrollY});

  final double progress;
  final double scrollY;

  @override
  void paint(Canvas canvas, Size size) {
    final rnd = math.Random(19);
    for (var i = 0; i < 64; i++) {
      final baseX = rnd.nextDouble() * size.width;
      final baseY = rnd.nextDouble() * size.height;
      final orbit = (progress + i * 0.04) % 1.0;
      final dx = math.sin(orbit * math.pi * 2) * 18;
      final dy = math.cos(orbit * math.pi * 2) * 12 - scrollY * 0.12;
      final alpha = 0.08 + rnd.nextDouble() * 0.2;
      final color = i.isEven
          ? UltraFortuneTokens.softLilac.withValues(alpha: alpha)
          : UltraFortuneTokens.metallicGold.withValues(alpha: alpha * 0.7);

      canvas.drawCircle(
        Offset(baseX + dx, baseY + dy),
        0.8 + rnd.nextDouble() * 2.2,
        Paint()
          ..color = color
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _CosmicParticlePainter old) =>
      old.progress != progress || old.scrollY != scrollY;
}
