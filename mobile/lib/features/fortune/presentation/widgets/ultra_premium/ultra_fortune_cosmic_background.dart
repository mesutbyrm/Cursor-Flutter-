import 'dart:math' as math;

import 'package:canlifal_social/core/performance/animation_perf.dart';
import 'package:flutter/material.dart';

import 'ultra_fortune_tokens.dart';

/// Katmanlı kozmik evren — nebula, yıldızlar, sis, parallax partiküller.
class UltraFortuneCosmicBackground extends StatefulWidget {
  const UltraFortuneCosmicBackground({
    super.key,
    required this.child,
    this.scrollOffset = 0,
    this.scrollParallax,
  });

  final Widget child;

  /// Geriye dönük — tercihen [scrollParallax] kullanın.
  final double scrollOffset;

  /// Scroll parallax — yalnızca arka plan katmanları rebuild olur.
  final ScrollParallaxNotifier? scrollParallax;

  @override
  State<UltraFortuneCosmicBackground> createState() =>
      _UltraFortuneCosmicBackgroundState();
}

class _UltraFortuneCosmicBackgroundState extends State<UltraFortuneCosmicBackground>
    with TickerProviderStateMixin {
  late final AnimationController _nebula;
  late final AnimationController _particles;
  late final AnimationController _fog;
  PrecomputedStarField? _stars;
  _CosmicOrbitField? _orbits;
  Size? _lastSize;

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

  void _ensureFields(Size size) {
    if (_lastSize == size && _stars != null && _orbits != null) return;
    _lastSize = size;
    _stars = PrecomputedStarField.generate(size: size, seed: 42, density: 1.0);
    _orbits = _CosmicOrbitField.generate(size);
  }

  @override
  void dispose() {
    _nebula.dispose();
    _particles.dispose();
    _fog.dispose();
    super.dispose();
  }

  double _parallaxOffset() =>
      widget.scrollParallax?.offset ?? widget.scrollOffset;

  Widget _animatedLayers(Size size, double parallax) {
    _ensureFields(size);
    return DeferredTickerMode(
      child: Stack(
        fit: StackFit.expand,
        children: [
          AnimationPerf.isolated(
            AnimatedBuilder(
              animation: _nebula,
              builder: (_, _) => CustomPaint(
                painter: _NebulaPainter(
                  breath: _nebula.value,
                  scrollY: parallax * 0.15,
                ),
                size: size,
              ),
            ),
          ),
          Transform.translate(
            offset: Offset(0, -parallax * 0.08),
            child: AnimationPerf.isolated(
              AnimatedBuilder(
                animation: _particles,
                builder: (_, _) => CustomPaint(
                  painter: _StarFieldPainter(
                    field: _stars!,
                    twinklePhase: _particles.value,
                  ),
                  size: size,
                ),
              ),
            ),
          ),
          AnimationPerf.isolated(
            AnimatedBuilder(
              animation: _fog,
              builder: (_, _) => CustomPaint(
                painter: _FogPainter(phase: _fog.value, scrollY: parallax * 0.25),
                size: size,
              ),
            ),
          ),
          AnimationPerf.isolated(
            AnimatedBuilder(
              animation: _particles,
              builder: (_, _) => CustomPaint(
                painter: _CosmicParticlePainter(
                  field: _orbits!,
                  progress: _particles.value,
                  scrollY: parallax * 0.35,
                ),
                size: size,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final parallax = widget.scrollParallax;

    return Stack(
      fit: StackFit.expand,
      children: [
        const DecoratedBox(
          decoration: BoxDecoration(gradient: UltraFortuneTokens.deepSpaceGradient),
        ),
        if (parallax != null)
          ListenableBuilder(
            listenable: parallax,
            builder: (_, _) => _animatedLayers(size, parallax.offset),
          )
        else
          _animatedLayers(size, _parallaxOffset()),
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

class _CosmicOrbitField {
  _CosmicOrbitField._(this.points);

  final List<_OrbitPoint> points;

  factory _CosmicOrbitField.generate(Size size) {
    final rnd = math.Random(19);
    return _CosmicOrbitField._(
      List.generate(64, (i) {
        return _OrbitPoint(
          baseX: rnd.nextDouble() * size.width,
          baseY: rnd.nextDouble() * size.height,
          alpha: 0.08 + rnd.nextDouble() * 0.2,
          radius: 0.8 + rnd.nextDouble() * 2.2,
          even: i.isEven,
          phase: i * 0.04,
        );
      }),
    );
  }
}

class _OrbitPoint {
  const _OrbitPoint({
    required this.baseX,
    required this.baseY,
    required this.alpha,
    required this.radius,
    required this.even,
    required this.phase,
  });

  final double baseX;
  final double baseY;
  final double alpha;
  final double radius;
  final bool even;
  final double phase;
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
  _StarFieldPainter({required this.field, this.twinklePhase = 0});

  final PrecomputedStarField field;
  final double twinklePhase;

  @override
  void paint(Canvas canvas, Size size) {
    for (var i = 0; i < field.points.length; i++) {
      final star = field.points[i];
      final twinkle = 0.35 +
          0.65 *
              (0.5 +
                  0.5 *
                      math.sin((twinklePhase + star.base) * math.pi * 2 + i * 0.3));
      final paint = Paint()
        ..color = Colors.white.withValues(alpha: 0.12 + star.base * 0.55 * twinkle);
      canvas.drawCircle(Offset(star.x, star.y), star.radius, paint);
      if (star.glow) {
        canvas.drawCircle(
          Offset(star.x, star.y),
          star.radius * 2.5,
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
      Rect.fromLTWH(
        -drift,
        size.height * 0.55 + scrollY * 0.2,
        size.width * 2,
        size.height * 0.5,
      ),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant _FogPainter old) =>
      old.phase != phase || old.scrollY != scrollY;
}

class _CosmicParticlePainter extends CustomPainter {
  _CosmicParticlePainter({
    required this.field,
    required this.progress,
    required this.scrollY,
  });

  final _CosmicOrbitField field;
  final double progress;
  final double scrollY;

  @override
  void paint(Canvas canvas, Size size) {
    for (final p in field.points) {
      final orbit = (progress + p.phase) % 1.0;
      final dx = math.sin(orbit * math.pi * 2) * 18;
      final dy = math.cos(orbit * math.pi * 2) * 12 - scrollY * 0.12;
      final color = p.even
          ? UltraFortuneTokens.softLilac.withValues(alpha: p.alpha)
          : UltraFortuneTokens.metallicGold.withValues(alpha: p.alpha * 0.7);

      canvas.drawCircle(
        Offset(p.baseX + dx, p.baseY + dy),
        p.radius,
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
