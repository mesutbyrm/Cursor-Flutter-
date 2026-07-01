import 'dart:async';

import 'package:dio/dio.dart';
import 'package:video_player/video_player.dart';

import '../../../../core/video/video_cache_service.dart';
import 'short_video_url_resolver.dart';

/// CDN / imzalı URL / API stream — `fastStart` ile ~300 ms hedef.
Future<VideoPlayerController> createShortVideoController({
  required String url,
  String? videoId,
  Dio? dio,
  bool fastStart = false,
}) async {
  final candidates = <String>[url.trim()];
  if (dio != null) {
    final resolver = ShortVideoUrlResolver(dio);
    final resolved = await resolver.resolvePlayUrls(
      videoUrl: url,
      videoId: videoId,
    );
    for (final u in resolved) {
      if (!candidates.contains(u)) candidates.add(u);
    }
  }

  if (candidates.isEmpty || candidates.every((u) => u.isEmpty)) {
    throw StateError('Video URL boş');
  }

  Object? lastError;
  final cache = VideoCacheService.instance;
  for (final playUrl in candidates) {
    if (playUrl.isEmpty) continue;
    VideoPlayerController? controller;
    try {
      if (fastStart) {
        final file = await cache.peekCachedFile(playUrl);
        if (file != null) {
          controller = VideoPlayerController.file(file);
        } else {
          controller = VideoPlayerController.networkUrl(Uri.parse(playUrl));
          unawaited(cache.prefetch(playUrl));
        }
      } else {
        final file = await cache.getCachedFile(playUrl);
        if (file != null && await file.exists()) {
          controller = VideoPlayerController.file(file);
        } else {
          controller = VideoPlayerController.networkUrl(Uri.parse(playUrl));
          unawaited(cache.prefetch(playUrl));
        }
      }

      final timeout = fastStart
          ? const Duration(milliseconds: 800)
          : const Duration(seconds: 12);
      await controller.initialize().timeout(timeout);
      if (controller.value.hasError) {
        throw StateError(controller.value.errorDescription ?? 'player_error');
      }
      controller.setLooping(true);
      return controller;
    } catch (e) {
      lastError = e;
      await controller?.dispose();
    }
  }

  throw lastError ?? StateError('Video oynatılamadı');
}

/// Sonraki videoları disk önbelleğine indirir — tam oynatıcı açmaz.
Future<void> preloadShortVideoUrl(
  String url, {
  String? videoId,
  Dio? dio,
}) async {
  if (url.isEmpty) return;
  final cache = VideoCacheService.instance;
  final candidates = <String>[url.trim()];
  if (dio != null) {
    try {
      final resolver = ShortVideoUrlResolver(dio);
      final resolved = await resolver.resolvePlayUrls(
        videoUrl: url,
        videoId: videoId,
      );
      for (final u in resolved) {
        if (!candidates.contains(u)) candidates.add(u);
      }
    } catch (_) {}
  }
  for (final playUrl in candidates) {
    if (playUrl.isEmpty) continue;
    try {
      await cache.prefetch(playUrl);
      return;
    } catch (_) {}
  }
}
