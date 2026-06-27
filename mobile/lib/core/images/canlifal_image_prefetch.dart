import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import 'canlifal_image_cache_manager.dart';
import 'canlifal_image_urls.dart';

/// Görselleri thumbnail olarak önceden disk/bellek cache'e alır.
Future<void> prefetchCanlifalImages(
  BuildContext context, {
  Iterable<String> urls = const [],
  int thumbnailWidth = CanlifalImageUrls.defaultThumbnailWidth,
}) async {
  if (!context.mounted) return;
  final dpr = MediaQuery.devicePixelRatioOf(context);
  final cacheW = (thumbnailWidth * dpr).round().clamp(120, 1440);

  for (final raw in urls.take(8)) {
    if (!context.mounted) return;
    final thumb = CanlifalImageUrls.thumbnail(raw, width: thumbnailWidth);
    if (thumb.isEmpty) continue;
    try {
      await precacheImage(
        CachedNetworkImageProvider(
          thumb,
          maxWidth: cacheW,
          cacheManager: CanlifalImageCacheManager.instance,
        ),
        context,
      );
    } catch (_) {}
  }
}
