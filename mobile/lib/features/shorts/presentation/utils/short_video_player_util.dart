import 'dart:async';

import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:video_player/video_player.dart';

/// CDN/R2 URL'den oynatma — önbellek varsa dosyadan, yoksa ağdan.
Future<VideoPlayerController> createShortVideoController({
  required String url,
  CacheManager? cacheManager,
}) async {
  if (url.isEmpty) {
    throw StateError('Video URL boş');
  }

  VideoPlayerController controller;
  if (cacheManager != null) {
    try {
      final file = await cacheManager.getSingleFile(url);
      controller = VideoPlayerController.file(file);
    } catch (_) {
      controller = VideoPlayerController.networkUrl(Uri.parse(url));
    }
  } else {
    controller = VideoPlayerController.networkUrl(Uri.parse(url));
  }

  await controller.initialize();
  controller.setLooping(true);
  return controller;
}

Future<void> preloadShortVideoUrl(String url, CacheManager cache) async {
  if (url.isEmpty) return;
  try {
    await cache.downloadFile(url);
  } catch (_) {}
}
