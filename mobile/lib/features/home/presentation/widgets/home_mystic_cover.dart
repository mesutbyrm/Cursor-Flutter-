import 'package:canlifal_social/core/images/canlifal_network_image.dart';
import 'package:flutter/material.dart';

import '../../../fortune/presentation/data/fortune_type_images.dart';
import '../../../fortune/presentation/widgets/fortune_type_cover_art.dart';

/// Ana sayfa kartları — yerel mistik sanat + asset + isteğe bağlı ağ görseli.
class HomeMysticCover extends StatelessWidget {
  const HomeMysticCover({
    super.key,
    required this.slug,
    required this.accent,
    this.networkUrl,
    this.thumbnailWidth = 480,
    this.fit = BoxFit.cover,
  });

  final String slug;
  final Color accent;
  final String? networkUrl;
  final int thumbnailWidth;
  final BoxFit fit;

  @override
  Widget build(BuildContext context) {
    final assetPath = FortuneTypeImages.assetPathFor(slug);
    final remote = networkUrl?.trim();

    return Stack(
      fit: StackFit.expand,
      children: [
        FortuneTypeCoverArt(slug: slug, accent: accent),
        if (assetPath != null)
          Image.asset(
            assetPath,
            fit: fit,
            errorBuilder: (_, _, _) => const SizedBox.shrink(),
          ),
        if (remote != null && remote.isNotEmpty)
          CanlifalNetworkImage(
            url: remote,
            fit: fit,
            thumbnailWidth: thumbnailWidth,
            errorWidget: const SizedBox.shrink(),
          ),
      ],
    );
  }
}
