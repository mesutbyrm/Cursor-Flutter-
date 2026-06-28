import 'package:flutter/material.dart';

import '../images/canlifal_network_image.dart';

export '../images/canlifal_image_urls.dart';
export '../images/canlifal_network_image.dart';

/// Liste / kart kapak görselleri — thumbnail + disk/bellek cache.
class CachedCoverImage extends StatelessWidget {
  const CachedCoverImage({
    super.key,
    required this.url,
    this.fit = BoxFit.cover,
    this.width,
    this.height,
    this.borderRadius,
    this.fallback,
    this.onTapOpenFull = false,
  });

  final String url;
  final BoxFit fit;
  final double? width;
  final double? height;
  final BorderRadius? borderRadius;
  final Widget? fallback;
  final bool onTapOpenFull;

  @override
  Widget build(BuildContext context) {
    return CanlifalNetworkImage(
      url: url,
      width: width,
      height: height,
      fit: fit,
      borderRadius: borderRadius,
      onTapOpenFull: onTapOpenFull,
      errorWidget: fallback,
      placeholder: fallback ?? _placeholder(),
    );
  }

  Widget _placeholder() {
    return ColoredBox(
      color: Colors.white.withValues(alpha: 0.06),
      child: const Center(
        child: Icon(Icons.image_outlined, color: Colors.white38, size: 28),
      ),
    );
  }
}
