import 'package:flutter/material.dart';

import '../../../domain/entities/fortune_type_entity.dart';
import '../fortune_type_cover_image.dart';
import '../premium_ai/fortune_dynamic_background.dart';

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
    return RepaintBoundary(
      child: FortuneDynamicBackground(
        type: type,
        child: Stack(
          fit: StackFit.expand,
          children: [
            FortuneTypeCoverImage(
              slug: type.slug,
              accent: type.accent,
              imageWidth: 1400,
            ),
            child,
          ],
        ),
      ),
    );
  }
}
