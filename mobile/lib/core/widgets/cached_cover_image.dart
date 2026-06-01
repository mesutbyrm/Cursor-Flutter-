import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

/// Liste / kart kapak görselleri — disk + bellek önbelleği.
class CachedCoverImage extends StatelessWidget {
  const CachedCoverImage({
    super.key,
    required this.url,
    this.fit = BoxFit.cover,
    this.width,
    this.height,
    this.borderRadius,
    this.fallback,
  });

  final String url;
  final BoxFit fit;
  final double? width;
  final double? height;
  final BorderRadius? borderRadius;
  final Widget? fallback;

  @override
  Widget build(BuildContext context) {
    Widget img = CachedNetworkImage(
      imageUrl: url,
      width: width,
      height: height,
      fit: fit,
      placeholder: (_, __) => _placeholder(),
      errorWidget: (_, __, ___) => fallback ?? _placeholder(),
    );

    if (borderRadius != null) {
      img = ClipRRect(borderRadius: borderRadius!, child: img);
    }
    return img;
  }

  Widget _placeholder() {
    return ColoredBox(
      color: Colors.white.withValues(alpha: 0.06),
      child: fallback ??
          const Center(
            child: Icon(Icons.image_outlined, color: Colors.white38, size: 28),
          ),
    );
  }
}
