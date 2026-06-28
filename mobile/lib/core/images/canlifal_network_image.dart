import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import 'canlifal_image_cache_manager.dart';
import 'canlifal_image_urls.dart';

/// Piksel genişliği — layout + DPR (bellek cache boyutu).
int canlifalImageCachePixels(
  BuildContext context, {
  double? width,
  double? height,
  int fallback = CanlifalImageUrls.defaultThumbnailWidth,
}) {
  final dpr = MediaQuery.devicePixelRatioOf(context);
  if (width != null && width.isFinite && width > 0) {
    return (width * dpr).round().clamp(48, CanlifalImageUrls.fullMaxWidth);
  }
  if (height != null && height.isFinite && height > 0) {
    return (height * dpr).round().clamp(48, CanlifalImageUrls.fullMaxWidth);
  }
  final screenW = MediaQuery.sizeOf(context).width;
  return (screenW * dpr).round().clamp(fallback, CanlifalImageUrls.fullMaxWidth);
}

/// [CircleAvatar] / [DecorationImage] için thumbnail provider.
CachedNetworkImageProvider canlifalImageProvider(
  String? url, {
  int width = CanlifalImageUrls.defaultThumbnailWidth,
  bool thumbnail = true,
}) {
  final resolved = thumbnail
      ? CanlifalImageUrls.thumbnail(url, width: width)
      : CanlifalImageUrls.full(url);
  return CachedNetworkImageProvider(
    resolved,
    maxWidth: thumbnail ? width : CanlifalImageUrls.fullMaxWidth,
    cacheManager: CanlifalImageCacheManager.instance,
  );
}

/// Tüm ağ görselleri — thumbnail varsayılan; tam çözünürlük isteğe bağlı.
class CanlifalNetworkImage extends StatelessWidget {
  const CanlifalNetworkImage({
    super.key,
    required this.url,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.borderRadius,
    this.placeholder,
    this.errorWidget,
    this.thumbnailWidth,
    this.loadFullResolution = false,
    this.fadeIn = true,
    this.onTapOpenFull = false,
    this.color,
    this.colorBlendMode,
  });

  /// Tam çözünürlük — detay / zoom.
  const CanlifalNetworkImage.full({
    super.key,
    required this.url,
    this.width,
    this.height,
    this.fit = BoxFit.contain,
    this.borderRadius,
    this.placeholder,
    this.errorWidget,
    this.fadeIn = true,
    this.color,
    this.colorBlendMode,
  })  : thumbnailWidth = null,
        loadFullResolution = true,
        onTapOpenFull = false;

  final String? url;
  final double? width;
  final double? height;
  final BoxFit fit;
  final BorderRadius? borderRadius;
  final Widget? placeholder;
  final Widget? errorWidget;
  final int? thumbnailWidth;
  final bool loadFullResolution;
  final bool fadeIn;
  final bool onTapOpenFull;
  final Color? color;
  final BlendMode? colorBlendMode;

  @override
  Widget build(BuildContext context) {
    final raw = url?.trim() ?? '';
    if (raw.isEmpty) {
      return _wrapClip(errorWidget ?? _defaultPlaceholder());
    }

    final cachePx = loadFullResolution
        ? null
        : (thumbnailWidth ??
            canlifalImageCachePixels(context, width: width, height: height));

    final imageUrl = loadFullResolution
        ? CanlifalImageUrls.full(raw)
        : CanlifalImageUrls.thumbnail(
            raw,
            width: cachePx ?? CanlifalImageUrls.defaultThumbnailWidth,
          );

    final w = width;
    final h = height;
    final memH = (!loadFullResolution &&
            cachePx != null &&
            w != null &&
            h != null &&
            w > 0)
        ? (cachePx * h / w).round()
        : null;

    Widget img = CachedNetworkImage(
      imageUrl: imageUrl,
      width: width,
      height: height,
      fit: fit,
      cacheManager: CanlifalImageCacheManager.instance,
      memCacheWidth: loadFullResolution ? null : cachePx,
      memCacheHeight: loadFullResolution ? null : memH,
      maxWidthDiskCache:
          loadFullResolution ? CanlifalImageUrls.fullMaxWidth : (cachePx ?? 480),
      maxHeightDiskCache:
          loadFullResolution ? CanlifalImageUrls.fullMaxWidth : null,
      fadeInDuration:
          fadeIn ? const Duration(milliseconds: 220) : Duration.zero,
      color: color,
      colorBlendMode: colorBlendMode,
      placeholder: (_, _) => placeholder ?? _defaultPlaceholder(),
      errorWidget: (_, _, _) => errorWidget ?? _defaultPlaceholder(),
    );

    if (onTapOpenFull && !loadFullResolution) {
      img = GestureDetector(
        onTap: () => CanlifalFullImageViewer.open(context, raw),
        child: img,
      );
    }

    return _wrapClip(img);
  }

  Widget _wrapClip(Widget child) {
    if (borderRadius != null) {
      return ClipRRect(borderRadius: borderRadius!, child: child);
    }
    return child;
  }

  Widget _defaultPlaceholder() {
    return ColoredBox(
      color: Colors.white.withValues(alpha: 0.06),
      child: const Center(
        child: Icon(Icons.image_outlined, color: Colors.white38, size: 28),
      ),
    );
  }
}

/// Tam ekran görsel — orijinal yalnızca açıldığında indirilir.
class CanlifalFullImageViewer extends StatelessWidget {
  const CanlifalFullImageViewer({super.key, required this.url});

  final String url;

  static Future<void> open(BuildContext context, String url) {
    final resolved = CanlifalImageUrls.full(url);
    if (resolved.isEmpty) return Future.value();
    return showDialog<void>(
      context: context,
      barrierColor: Colors.black87,
      builder: (ctx) => CanlifalFullImageViewer(url: url),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog.fullscreen(
      backgroundColor: Colors.black,
      child: Stack(
        children: [
          Center(
            child: InteractiveViewer(
              minScale: 0.6,
              maxScale: 4,
              child: CanlifalNetworkImage.full(
                url: url,
                fit: BoxFit.contain,
              ),
            ),
          ),
          SafeArea(
            child: Align(
              alignment: Alignment.topRight,
              child: IconButton(
                icon: const Icon(Icons.close_rounded, color: Colors.white),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
