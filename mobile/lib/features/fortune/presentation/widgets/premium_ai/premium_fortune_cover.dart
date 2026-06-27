import 'dart:math' as math;
import 'dart:ui';

import 'package:canlifal_social/core/images/canlifal_network_image.dart';
import 'package:flutter/material.dart';

import '../../data/fortune_type_images.dart';
import '../../../domain/entities/fortune_type_entity.dart';
import '../fortune_type_network_image.dart';
import '../ultra_premium/ultra_fortune_tokens.dart';
import 'fortune_image_shimmer.dart';

/// Tam genişlik premium fal kapağı — parallax, glassmorphism, hero.
class PremiumFortuneCover extends StatefulWidget {
  const PremiumFortuneCover({
    super.key,
    required this.type,
    this.height = 320,
    this.scrollOffset = 0,
    this.imageUrl,
    this.heroTag,
  });

  final FortuneTypeEntity type;
  final double height;
  final double scrollOffset;
  final String? imageUrl;
  final String? heroTag;

  @override
  State<PremiumFortuneCover> createState() => _PremiumFortuneCoverState();
}

class _PremiumFortuneCoverState extends State<PremiumFortuneCover>
    with SingleTickerProviderStateMixin {
  late final AnimationController _shimmer;

  @override
  void initState() {
    super.initState();
    _shimmer = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();
  }

  @override
  void dispose() {
    _shimmer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final url = widget.imageUrl ?? FortuneTypeImages.urlFor(widget.type.slug, width: 1200);
    final parallax = widget.scrollOffset * 0.35;
    final accent = widget.type.accent;
    final tag = widget.heroTag ?? FortuneTypeImages.heroTagFor(widget.type.slug);

    Widget imageLayer = Transform.translate(
      offset: Offset(0, parallax),
      child: Transform.scale(
        scale: 1.06,
        child: widget.imageUrl != null
            ? CanlifalNetworkImage(
                url: url,
                fit: BoxFit.cover,
                thumbnailWidth: 1200,
                placeholder: FortuneImageShimmer(accent: accent),
              )
            : FortuneTypeNetworkImage(
                slug: widget.type.slug,
                accent: accent,
                borderRadius: 0,
                imageWidth: 1200,
                heroTag: tag,
              ),
      ),
    );

    if (widget.imageUrl != null) {
      imageLayer = Hero(
        tag: tag,
        child: Material(type: MaterialType.transparency, child: imageLayer),
      );
    }

    return RepaintBoundary(
      child: SizedBox(
        height: widget.height,
        width: double.infinity,
        child: ClipRRect(
          borderRadius: const BorderRadius.vertical(bottom: Radius.circular(28)),
          child: Stack(
            fit: StackFit.expand,
            children: [
              imageLayer,
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    accent.withValues(alpha: 0.15),
                    Colors.black.withValues(alpha: 0.35),
                    const Color(0xFF0A0118).withValues(alpha: 0.92),
                  ],
                ),
              ),
            ),
            AnimatedBuilder(
              animation: _shimmer,
              builder: (_, _) {
                return CustomPaint(
                  painter: _MysticLightPainter(
                    progress: _shimmer.value,
                    accent: accent,
                  ),
                );
              },
            ),
            Positioned(
              left: 16,
              right: 16,
              bottom: 20,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: UltraFortuneTokens.metallicGold.withValues(alpha: 0.35),
                      ),
                      gradient: LinearGradient(
                        colors: [
                          Colors.white.withValues(alpha: 0.14),
                          Colors.white.withValues(alpha: 0.04),
                        ],
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: accent.withValues(alpha: 0.2),
                            border: Border.all(
                              color: UltraFortuneTokens.metallicGold.withValues(alpha: 0.4),
                            ),
                          ),
                          child: Icon(
                            Icons.auto_awesome_rounded,
                            color: accent.withValues(alpha: 0.95),
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.type.title,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w900,
                                  fontSize: 18,
                                ),
                              ),
                              Text(
                                widget.type.description,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.78),
                                  fontSize: 12,
                                  height: 1.3,
                                ),
                              ),
                            ],
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
    );
  }
}

class _MysticLightPainter extends CustomPainter {
  _MysticLightPainter({required this.progress, required this.accent});

  final double progress;
  final Color accent;

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width * (0.3 + 0.4 * math.sin(progress * math.pi * 2));
    final paint = Paint()
      ..shader = RadialGradient(
        colors: [
          accent.withValues(alpha: 0.22),
          UltraFortuneTokens.metallicGold.withValues(alpha: 0.08),
          Colors.transparent,
        ],
      ).createShader(Rect.fromCircle(center: Offset(cx, size.height * 0.3), radius: 120));
    canvas.drawRect(Offset.zero & size, paint);
  }

  @override
  bool shouldRepaint(covariant _MysticLightPainter old) =>
      old.progress != progress;
}
