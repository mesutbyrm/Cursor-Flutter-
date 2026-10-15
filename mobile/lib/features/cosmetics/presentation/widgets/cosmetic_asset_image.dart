import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:lottie/lottie.dart';

import '../../../../core/config/env.dart';
import '../../../../core/images/canlifal_network_image.dart';

/// Sitedeki kozmetik görselleri (`/frames/*.png`, `/cosmetics/**/*.svg`,
/// lottie/gif) — göreli yollar site adresiyle tamamlanır.
String cosmeticAssetUrl(String raw) {
  final u = raw.trim();
  if (u.startsWith('http://') || u.startsWith('https://')) return u;
  final origin = Env.siteOrigin.replaceAll(RegExp(r'/+$'), '');
  return u.startsWith('/') ? '$origin$u' : '$origin/$u';
}

class CosmeticAssetImage extends StatelessWidget {
  const CosmeticAssetImage({
    super.key,
    required this.url,
    this.width,
    this.height,
    this.fit = BoxFit.contain,
    this.assetType,
  });

  final String url;
  final double? width;
  final double? height;
  final BoxFit fit;
  final String? assetType;

  @override
  Widget build(BuildContext context) {
    final full = cosmeticAssetUrl(url);
    final path = Uri.tryParse(full)?.path.toLowerCase() ?? full.toLowerCase();
    final type = (assetType ?? '').toLowerCase();
    const fallback = SizedBox.shrink();
    if (path.endsWith('.svg') || type == 'svg') {
      return SvgPicture.network(
        full,
        width: width,
        height: height,
        fit: fit,
        placeholderBuilder: (_) => SizedBox(width: width, height: height),
      );
    }
    if (path.endsWith('.json') || type == 'lottie') {
      return Lottie.network(
        full,
        width: width,
        height: height,
        fit: fit,
        errorBuilder: (_, _, _) => fallback,
      );
    }
    return CanlifalNetworkImage(
      url: full,
      width: width,
      height: height,
      fit: fit,
      errorWidget: fallback,
    );
  }
}
