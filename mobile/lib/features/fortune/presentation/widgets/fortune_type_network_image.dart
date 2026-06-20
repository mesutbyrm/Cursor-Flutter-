import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../data/fortune_type_images.dart';
import 'premium_ai/fortune_image_shimmer.dart';

/// Fal türü vitrin görseli — shimmer, hero, premium gradient overlay.
class FortuneTypeNetworkImage extends StatelessWidget {
  const FortuneTypeNetworkImage({
    super.key,
    required this.slug,
    required this.accent,
    this.height,
    this.borderRadius = 16,
    this.fit = BoxFit.cover,
    this.heroTag,
    this.imageWidth = 800,
  });

  final String slug;
  final Color accent;
  final double? height;
  final double borderRadius;
  final BoxFit fit;
  final String? heroTag;
  final int imageWidth;

  @override
  Widget build(BuildContext context) {
    final url = FortuneTypeImages.urlFor(slug, width: imageWidth);
    final tag = heroTag ?? FortuneTypeImages.heroTagFor(slug);
    final overlays = FortuneTypeImages.overlayColors(slug);

    Widget image = RepaintBoundary(
      child: CachedNetworkImage(
        imageUrl: url,
        fit: fit,
        fadeInDuration: const Duration(milliseconds: 400),
        memCacheWidth: imageWidth,
        placeholder: (_, _) => FortuneImageShimmer(accent: accent),
        errorWidget: (_, _, _) => FortuneImageShimmer(accent: accent),
      ),
    );

    image = Hero(
      tag: tag,
      child: Material(
        type: MaterialType.transparency,
        child: image,
      ),
    );

    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: SizedBox(
        height: height,
        width: double.infinity,
        child: Stack(
          fit: StackFit.expand,
          children: [
            image,
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: overlays.length >= 3
                      ? overlays
                      : [
                          Colors.transparent,
                          accent.withValues(alpha: 0.15),
                          Colors.black.withValues(alpha: 0.5),
                        ],
                ),
              ),
            ),
            IgnorePointer(
              child: CustomPaint(painter: _SparklePainter(accent: accent)),
            ),
          ],
        ),
      ),
    );
  }
}

class _SparklePainter extends CustomPainter {
  _SparklePainter({required this.accent});

  final Color accent;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = accent.withValues(alpha: 0.15);
    const points = [
      Offset(0.15, 0.2),
      Offset(0.82, 0.15),
      Offset(0.7, 0.55),
      Offset(0.25, 0.72),
    ];
    for (final p in points) {
      canvas.drawCircle(
        Offset(size.width * p.dx, size.height * p.dy),
        2,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _SparklePainter old) => false;
}
