import 'package:flutter/material.dart';

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
    // StackFit.expand kullanılmaz — üst Stack sınırsız yükseklikte
    // "infinite height" layout hatasına yol açar (Fal hub boş ekran).
    return IgnorePointer(
      child: Opacity(
        opacity: opacity,
        child: FortuneTypeCoverImage(
          slug: slug,
          accent: accent,
          imageWidth: imageWidth,
          showOverlay: true,
        ),
      ),
    );
  }
}
