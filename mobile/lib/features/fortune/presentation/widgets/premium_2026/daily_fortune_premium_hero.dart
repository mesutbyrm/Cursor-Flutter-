import 'dart:math' as math;

import 'package:canlifal_social/core/images/canlifal_network_image.dart';
import 'package:canlifal_social/core/performance/animation_perf.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../data/fortune_type_images.dart';
import '../premium_ai/fortune_image_shimmer.dart';

/// Günlük fal açılış hero — tarot kartı, enerji halkaları, nebula, partiküller.
class DailyFortunePremiumHero extends StatefulWidget {
  const DailyFortunePremiumHero({
    super.key,
    this.height = 280,
    this.parallaxOffset = 0,
    this.scrollParallax,
  });

  final double height;
  final double parallaxOffset;
  final ScrollParallaxNotifier? scrollParallax;

  @override
  State<DailyFortunePremiumHero> createState() => _DailyFortunePremiumHeroState();
}

class _DailyFortunePremiumHeroState extends State<DailyFortunePremiumHero>
    with TickerProviderStateMixin {
  late final AnimationController _rings;
  late final AnimationController _particles;

  @override
  void initState() {
    super.initState();
    _rings = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 18),
    )..repeat();
    _particles = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 12),
    )..repeat();
  }

  @override
  void dispose() {
    _rings.dispose();
    _particles.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final parallaxNotifier = widget.scrollParallax;
    if (parallaxNotifier != null) {
      return ListenableBuilder(
        listenable: parallaxNotifier,
        builder: (_, _) => _buildContent(parallaxNotifier.offset),
      );
    }
    return _buildContent(widget.parallaxOffset);
  }

  Widget _buildContent(double scrollOffset) {
    final url = FortuneTypeImages.urlFor('gunluk-fal', width: 1200);
    final glow = FortuneTypeImages.glowColor('tarot');
    final parallax = scrollOffset * 0.2;

    return RepaintBoundary(
      child: SizedBox(
        height: widget.height,
        width: double.infinity,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(30),
          child: Stack(
            fit: StackFit.expand,
            children: [
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: const Alignment(0.2, -0.3),
                    radius: 1.2,
                    colors: [
                      const Color(0xFF4C1D95),
                      const Color(0xFF1E0A3A),
                      const Color(0xFF0A0118),
                    ],
                  ),
                ),
              ),
              Transform.translate(
                offset: Offset(0, parallax),
                child: CanlifalNetworkImage(
                  url: url,
                  fit: BoxFit.cover,
                  thumbnailWidth: 1000,
                  color: Colors.white.withValues(alpha: 0.35),
                  colorBlendMode: BlendMode.softLight,
                  placeholder: const FortuneImageShimmer(accent: Color(0xFFB832FF)),
                ),
              ),
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: FortuneTypeImages.overlayColors('gunluk-fal'),
                  ),
                ),
              ),
              AnimatedBuilder(
                animation: _rings,
                builder: (_, _) => CustomPaint(
                  painter: _EnergyRingsPainter(
                    t: _rings.value,
                    color: glow,
                  ),
                ),
              ),
              AnimatedBuilder(
                animation: _particles,
                builder: (_, _) => CustomPaint(
                  painter: _FloatingParticlesPainter(t: _particles.value),
                ),
              ),
              Center(
                child: Transform.translate(
                  offset: Offset(0, parallax * 0.5),
                  child: _TarotCardStack(glow: glow),
                ),
              ),
            ],
          ),
        ),
      ),
    ).animate().fadeIn(duration: 600.ms).scale(
          begin: const Offset(0.96, 0.96),
          end: const Offset(1, 1),
          curve: Curves.easeOutCubic,
        );
  }
}

class _TarotCardStack extends StatelessWidget {
  const _TarotCardStack({required this.glow});

  final Color glow;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 120,
      height: 170,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Transform.rotate(
            angle: -0.12,
            child: _CardFace(
              glow: glow,
              width: 88,
              height: 130,
              opacity: 0.55,
            ),
          ),
          Transform.rotate(
            angle: 0.1,
            child: _CardFace(
              glow: glow,
              width: 92,
              height: 136,
              opacity: 0.75,
            ),
          ),
          _CardFace(glow: glow, width: 96, height: 142, opacity: 1),
        ],
      ),
    );
  }
}

class _CardFace extends StatelessWidget {
  const _CardFace({
    required this.glow,
    required this.width,
    required this.height,
    required this.opacity,
  });

  final Color glow;
  final double width;
  final double height;
  final double opacity;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: opacity,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: const Color(0xFFFFD700).withValues(alpha: 0.55),
            width: 1.4,
          ),
          boxShadow: [
            BoxShadow(
              color: glow.withValues(alpha: 0.45),
              blurRadius: 24,
              spreadRadius: 1,
            ),
          ],
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF3D1A6E),
              Color(0xFF1A0A32),
              Color(0xFF0F0520),
            ],
          ),
        ),
        child: Center(
          child: Icon(
            Icons.auto_awesome_rounded,
            color: glow.withValues(alpha: 0.9),
            size: width * 0.32,
          ),
        ),
      ),
    );
  }
}

class _EnergyRingsPainter extends CustomPainter {
  _EnergyRingsPainter({required this.t, required this.color});

  final double t;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width * 0.5, size.height * 0.42);
    for (var i = 0; i < 3; i++) {
      final phase = t * math.pi * 2 + i * 2.1;
      final radius = 52.0 + i * 28 + math.sin(phase) * 6;
      final paint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2 + i * 0.3
        ..color = color.withValues(alpha: 0.22 - i * 0.04);
      canvas.drawCircle(center, radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _EnergyRingsPainter old) => old.t != t;
}

class _FloatingParticlesPainter extends CustomPainter {
  _FloatingParticlesPainter({required this.t});

  final double t;

  @override
  void paint(Canvas canvas, Size size) {
    final rng = math.Random(11);
    final paint = Paint()..color = Colors.white.withValues(alpha: 0.4);
    for (var i = 0; i < 24; i++) {
      final bx = rng.nextDouble();
      final by = rng.nextDouble();
      final drift = math.sin(t * math.pi * 2 + i) * 8;
      canvas.drawCircle(
        Offset(bx * size.width + drift, by * size.height - drift * 0.5),
        0.6 + rng.nextDouble() * 1.2,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _FloatingParticlesPainter old) => old.t != t;
}
