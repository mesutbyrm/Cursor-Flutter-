import 'package:canlifal_social/core/images/canlifal_network_image.dart';
import 'package:flutter/material.dart';

import '../data/fortune_type_images.dart';
import 'fortune_type_cover_art.dart';
import 'premium_ai/fortune_image_shimmer.dart';

/// Fal türü kapak — yerel sanat + ağ görseli katmanı.
class FortuneTypeCoverImage extends StatelessWidget {
  const FortuneTypeCoverImage({
    super.key,
    required this.slug,
    required this.accent,
    this.fit = BoxFit.cover,
    this.imageWidth = 1400,
    this.showOverlay = true,
    this.networkUrlOverride,
  });

  final String slug;
  final Color accent;
  final BoxFit fit;
  final int imageWidth;
  final bool showOverlay;

  /// API/CDN kapak — yoksa yerel asset + Unsplash yedek.
  final String? networkUrlOverride;

  @override
  Widget build(BuildContext context) {
    final override = networkUrlOverride?.trim();
    final url = override != null && override.isNotEmpty
        ? override
        : FortuneTypeImages.urlFor(slug, width: imageWidth);
    final assetPath = FortuneTypeImages.assetPathFor(slug);
    final hasLocalAsset = assetPath != null;
    final overlays = FortuneTypeImages.overlayColors(slug);
    final glow = FortuneTypeImages.glowColor(slug);

    return Stack(
      fit: StackFit.expand,
      children: [
        if (hasLocalAsset)
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  glow.withValues(alpha: 0.45),
                  accent.withValues(alpha: 0.28),
                  const Color(0xFF0A0118),
                ],
              ),
            ),
          )
        else
          FortuneTypeCoverArt(slug: slug, accent: accent),
        if (hasLocalAsset)
          Image.asset(
            assetPath!,
            fit: fit,
            errorBuilder: (_, _, _) => const SizedBox.shrink(),
          )
        else
          CanlifalNetworkImage(
            url: url,
            fit: fit,
            thumbnailWidth: imageWidth > 1080 ? 1080 : imageWidth,
            placeholder: FortuneImageShimmer(accent: accent),
            errorWidget: const SizedBox.shrink(),
          ),
        if (showOverlay)
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: overlays,
              ),
            ),
          ),
      ],
    );
  }
}
