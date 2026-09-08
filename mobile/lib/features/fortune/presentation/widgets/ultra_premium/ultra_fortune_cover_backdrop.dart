import 'package:flutter/material.dart';

import '../../data/fortune_type_images.dart';
import '../fortune_type_cover_image.dart';

/// Ultra Premium kartlar için mistik kapak arka planı.
class UltraFortuneCoverBackdrop extends StatelessWidget {
  const UltraFortuneCoverBackdrop({
    super.key,
    required this.slug,
    required this.accent,
    this.opacity = 0.38,
    this.imageWidth = 520,
  });

  final String slug;
  final Color accent;
  final double opacity;
  final int imageWidth;

  @override
  Widget build(BuildContext context) {
    final glow = FortuneTypeImages.glowColor(slug);
    return IgnorePointer(
      child: Stack(
        fit: StackFit.expand,
        children: [
          Opacity(
            opacity: opacity,
            child: FortuneTypeCoverImage(
              slug: slug,
              accent: accent,
              imageWidth: imageWidth,
              showOverlay: true,
            ),
          ),
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  glow.withValues(alpha: 0.12),
                  Colors.black.withValues(alpha: 0.55),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
