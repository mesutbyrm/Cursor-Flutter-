import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:canlifal_social/core/theme/app_theme_colors.dart';

import '../platform_blur.dart';


/// Karanlık galaksi gradient + neon orb + yüzen parçacıklar (auth / splash).
class CosmicGalaxyBackground extends StatefulWidget {
  const CosmicGalaxyBackground({
    super.key,
    this.child = const SizedBox.expand(),
    this.showVignette = true,
    this.animate = true,
  });

  final Widget child;
  final bool showVignette;
  /// Ana sayfa kaydırması için animasyon ve blur kapalı (GPU yükü).
  final bool animate;

  @override
  State<CosmicGalaxyBackground> createState() => _CosmicGalaxyBackgroundState();
}

class _CosmicGalaxyBackgroundState extends State<CosmicGalaxyBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _drift;

  static bool get _useOrbBlur => PlatformBlur.supportsBackdropBlur;

  static const _galaxy = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF1A0E38),
      Color(0xFF12082A),
      Color(0xFF0A0618),
    ],
  );

  @override
  void initState() {
    super.initState();
    _drift = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    );
    if (widget.animate) {
      _drift.repeat();
    }
  }

  @override
  void didUpdateWidget(covariant CosmicGalaxyBackground oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.animate != widget.animate) {
      if (widget.animate) {
        _drift.repeat();
      } else {
        _drift.stop();
      }
    }
  }

  @override
  void dispose() {
    _drift.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final h = MediaQuery.sizeOf(context).height;
    final w = MediaQuery.sizeOf(context).width;

    return Stack(
      fit: StackFit.expand,
      children: [
        const DecoratedBox(decoration: BoxDecoration(gradient: _galaxy)),
        if (widget.animate) ...[
          Positioned(
            top: -90,
            right: -50,
            child: _useOrbBlur
                ? _neonOrb(AppThemeColors.accentPurple, 240)
                : _staticOrb(AppThemeColors.accentPurple, 240),
          ),
          Positioned(
            bottom: h * 0.12,
            left: -70,
            child: _useOrbBlur
                ? _neonOrb(const Color(0xFFFF2D7A), 200)
                : _staticOrb(const Color(0xFFFF2D7A), 200),
          ),
          Positioned(
            top: h * 0.32,
            left: w * 0.15,
            child: _useOrbBlur
                ? _neonOrb(AppThemeColors.accentCyan, 130, opacity: 0.22)
                : _staticOrb(AppThemeColors.accentCyan, 130, opacity: 0.22),
          ),
          AnimatedBuilder(
            animation: _drift,
            builder: (_, __) => CustomPaint(
              painter: _GalaxyParticlePainter(progress: _drift.value),
              size: Size.infinite,
            ),
          ),
        ] else ...[
          Positioned(top: -90, right: -50, child: _staticOrb(AppThemeColors.accentPurple, 220)),
          Positioned(
            bottom: h * 0.12,
            left: -70,
            child: _staticOrb(const Color(0xFFFF2D7A), 180),
          ),
        ],
        if (widget.showVignette)
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withValues(alpha: 0.08),
                  Colors.black.withValues(alpha: 0.45),
                ],
                stops: const [0.55, 1.0],
              ),
            ),
          ),
        widget.child,
      ],
    );
  }

  Widget _neonOrb(Color color, double size, {double opacity = 0.38}) {
    return ImageFiltered(
      imageFilter: ImageFilter.blur(sigmaX: 48, sigmaY: 48),
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [
              color.withValues(alpha: opacity),
              Colors.transparent,
            ],
          ),
        ),
      ),
    );
  }

  Widget _staticOrb(Color color, double size, {double opacity = 0.28}) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [
            color.withValues(alpha: opacity),
            Colors.transparent,
          ],
        ),
      ),
    );
  }
}

class _GalaxyParticlePainter extends CustomPainter {
  _GalaxyParticlePainter({required this.progress});

  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final rnd = math.Random(7);
    for (var i = 0; i < 42; i++) {
      final baseX = rnd.nextDouble() * size.width;
      final baseY = rnd.nextDouble() * size.height;
      final drift = math.sin((progress + i * 0.06) * math.pi * 2) * 10;
      final paint = Paint()
        ..color = Colors.white.withValues(alpha: 0.06 + rnd.nextDouble() * 0.14)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.5);
      canvas.drawCircle(
        Offset(baseX + drift, baseY - drift * 0.4),
        0.7 + rnd.nextDouble() * 1.8,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _GalaxyParticlePainter old) =>
      old.progress != progress;
}
