import 'dart:math' as math;
import 'dart:ui';

import 'package:canlifal_social/core/performance/animation_perf.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:canlifal_social/core/images/canlifal_network_image.dart';

import '../../../domain/entities/fortune_type_entity.dart';
import '../../data/fortune_type_images.dart';
import '../premium_ai/fortune_image_shimmer.dart';

/// Fal türüne özel sinematik hero — 280-350px, parallax, yıldızlar.
class CinematicFortuneHero extends StatefulWidget {
  const CinematicFortuneHero({
    super.key,
    required this.type,
    this.height = 320,
    this.scrollOffset = 0,
    this.scrollParallax,
    this.showTitle = true,
  });

  final FortuneTypeEntity type;
  final double height;
  final double scrollOffset;
  final ScrollParallaxNotifier? scrollParallax;
  final bool showTitle;

  @override
  State<CinematicFortuneHero> createState() => _CinematicFortuneHeroState();
}

class _CinematicFortuneHeroState extends State<CinematicFortuneHero>
    with SingleTickerProviderStateMixin {
  late final AnimationController _stars;

  @override
  void initState() {
    super.initState();
    _stars = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 24),
    )..repeat();
  }

  @override
  void dispose() {
    _stars.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final type = widget.type;
    final url = FortuneTypeImages.urlFor(type.slug, width: 1600);
    final tag = FortuneTypeImages.heroTagFor(type.slug);
    final glow = FortuneTypeImages.glowColor(type.slug);

    Widget parallaxImage() {
      Widget imageAt(double y) {
        return Transform.translate(
          offset: Offset(0, y),
          child: Transform.scale(
            scale: 1.08,
            child: Hero(
              tag: tag,
              child: Material(
                type: MaterialType.transparency,
                child: CanlifalNetworkImage(
                  url: url,
                  fit: BoxFit.cover,
                  placeholder: FortuneImageShimmer(accent: type.accent),
                  errorWidget: FortuneImageShimmer(accent: type.accent),
                ),
              ),
            ),
          ),
        );
      }

      final parallaxNotifier = widget.scrollParallax;
      if (parallaxNotifier == null) {
        return imageAt(widget.scrollOffset * 0.28);
      }
      return ListenableBuilder(
        listenable: parallaxNotifier,
        builder: (_, _) => imageAt(parallaxNotifier.offset * 0.28),
      );
    }

    return RepaintBoundary(
      child: SizedBox(
        height: widget.height,
        width: double.infinity,
        child: ClipRRect(
          borderRadius: const BorderRadius.vertical(bottom: Radius.circular(32)),
          child: Stack(
            fit: StackFit.expand,
            children: [
              parallaxImage(),
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: FortuneTypeImages.overlayColors(type.slug),
                  ),
                ),
              ),
              AnimatedBuilder(
                animation: _stars,
                builder: (_, _) => CustomPaint(
                  painter: _StarDriftPainter(t: _stars.value, color: glow),
                ),
              ),
              if (widget.showTitle)
                Positioned(
                  left: 20,
                  right: 20,
                  bottom: 24,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 18,
                          vertical: 14,
                        ),
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: glow.withValues(alpha: 0.35),
                          ),
                          gradient: LinearGradient(
                            colors: [
                              Colors.white.withValues(alpha: 0.14),
                              Colors.black.withValues(alpha: 0.35),
                            ],
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              type.title.toUpperCase(),
                              style: GoogleFonts.playfairDisplay(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                                fontSize: 22,
                                letterSpacing: 0.8,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              type.description,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.8),
                                fontSize: 12,
                                height: 1.35,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    ).animate().fadeIn(duration: 600.ms);
  }
}

class _StarDriftPainter extends CustomPainter {
  _StarDriftPainter({required this.t, required this.color});

  final double t;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final rng = math.Random(7);
    final paint = Paint()..color = Colors.white.withValues(alpha: 0.35);
    for (var i = 0; i < 20; i++) {
      final bx = rng.nextDouble();
      final by = rng.nextDouble();
      final drift = math.sin(t * math.pi * 2 + i) * 4;
      canvas.drawCircle(
        Offset(bx * size.width + drift, by * size.height),
        0.8 + rng.nextDouble(),
        paint,
      );
    }
    final beam = Paint()
      ..shader = LinearGradient(
        colors: [Colors.transparent, color.withValues(alpha: 0.12), Colors.transparent],
      ).createShader(Rect.fromLTWH(size.width * t - 60, 0, 120, size.height));
    canvas.drawRect(Offset.zero & size, beam);
  }

  @override
  bool shouldRepaint(covariant _StarDriftPainter old) => old.t != t;
}
