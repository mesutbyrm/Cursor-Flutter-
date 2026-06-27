import 'package:flutter/material.dart';

import '../../../../core/images/canlifal_image_prefetch.dart';

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
  await prefetchCanlifalImages(context, urls: urls);
}
