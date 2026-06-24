import 'dart:ui';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../../domain/entities/fortune_type_entity.dart';
import '../../data/fortune_type_images.dart';
import '../premium_ai/fortune_dynamic_background.dart';
import '../premium_ai/fortune_image_shimmer.dart';

/// Fal türüne özel tam ekran kapak + kozmik arka plan.
class FortuneTypeImmersiveScaffold extends StatelessWidget {
  const FortuneTypeImmersiveScaffold({
    super.key,
    required this.type,
    required this.child,
  });

  final FortuneTypeEntity type;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final url = FortuneTypeImages.urlFor(type.slug, width: 1400);
    final overlays = FortuneTypeImages.overlayColors(type.slug);

    return RepaintBoundary(
      child: FortuneDynamicBackground(
        type: type,
        child: Stack(
          fit: StackFit.expand,
          children: [
            CachedNetworkImage(
              imageUrl: url,
              fit: BoxFit.cover,
              memCacheWidth: 1080,
              fadeInDuration: const Duration(milliseconds: 280),
              placeholder: (_, _) => FortuneImageShimmer(accent: type.accent),
              errorWidget: (_, _, _) => const ColoredBox(color: Color(0xFF0A0118)),
            ),
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: overlays,
                ),
              ),
            ),
            BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 0.5, sigmaY: 0.5),
              child: const SizedBox.expand(),
            ),
            child,
          ],
        ),
      ),
    );
  }
}
