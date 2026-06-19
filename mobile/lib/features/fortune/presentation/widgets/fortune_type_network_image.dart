import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../data/fortune_type_images.dart';

/// Fal türü vitrin görseli — ağ görseli + gradient + emoji yedek.
class FortuneTypeNetworkImage extends StatelessWidget {
  const FortuneTypeNetworkImage({
    super.key,
    required this.slug,
    required this.accent,
    this.emoji,
    this.height,
    this.borderRadius = 16,
    this.fit = BoxFit.cover,
  });

  final String slug;
  final Color accent;
  final String? emoji;
  final double? height;
  final double borderRadius;
  final BoxFit fit;

  @override
  Widget build(BuildContext context) {
    final url = FortuneTypeImages.urlFor(slug);

    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: SizedBox(
        height: height,
        width: double.infinity,
        child: Stack(
          fit: StackFit.expand,
          children: [
            CachedNetworkImage(
              imageUrl: url,
              fit: fit,
              fadeInDuration: const Duration(milliseconds: 350),
              placeholder: (_, _) => _Placeholder(accent: accent, emoji: emoji),
              errorWidget: (_, _, _) => _Placeholder(accent: accent, emoji: emoji),
            ),
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    accent.withValues(alpha: 0.12),
                    Colors.black.withValues(alpha: 0.45),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Placeholder extends StatelessWidget {
  const _Placeholder({required this.accent, this.emoji});

  final Color accent;
  final String? emoji;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: accent.withValues(alpha: 0.18),
      alignment: Alignment.center,
      child: emoji != null
          ? Text(emoji!, style: const TextStyle(fontSize: 48))
          : Icon(Icons.auto_awesome, color: accent.withValues(alpha: 0.8), size: 40),
    );
  }
}
