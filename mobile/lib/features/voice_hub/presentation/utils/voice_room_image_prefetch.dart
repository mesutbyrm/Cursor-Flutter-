import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

/// Oda arka planlarını önbelleğe al — picker ve sahne hızlı açılsın.
Future<void> prefetchVoiceRoomImages(
  BuildContext context, {
  String? primaryUrl,
  Iterable<String> extraUrls = const [],
}) async {
  final urls = <String>{
    if (primaryUrl != null && primaryUrl.trim().isNotEmpty) primaryUrl.trim(),
    for (final u in extraUrls)
      if (u.trim().isNotEmpty) u.trim(),
  };
  if (urls.isEmpty || !context.mounted) return;

  final mq = MediaQuery.sizeOf(context);
  final dpr = MediaQuery.devicePixelRatioOf(context);
  final cacheW = (mq.width * dpr).round().clamp(360, 1440);

  for (final url in urls.take(16)) {
    if (!context.mounted) return;
    try {
      await precacheImage(
        CachedNetworkImageProvider(url, maxWidth: cacheW),
        context,
      );
    } catch (_) {}
  }
}
