import 'dart:async';

import 'package:dio/dio.dart';
import 'package:video_player/video_player.dart';

import '../../../core/video/video_cache_service.dart';
import 'short_video_url_resolver.dart';

/// CDN / imzalı URL / API stream sırasıyla oynatıcı oluşturur.
Future<VideoPlayerController> createShortVideoController({
  required String url,
  String? videoId,
  Dio? dio,
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
      final file = await cache.getCachedFile(playUrl);
      if (file != null && await file.exists()) {
        controller = VideoPlayerController.file(file);
      } else {
        controller = VideoPlayerController.networkUrl(Uri.parse(playUrl));
        unawaited(cache.prefetch(playUrl));
      }
      await controller.initialize().timeout(const Duration(seconds: 25));
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

Future<void> preloadShortVideoUrl(
  String url, {
  String? videoId,
  Dio? dio,
}) async {
  if (url.isEmpty) return;
  VideoPlayerController? controller;
  try {
    controller = await createShortVideoController(
      url: url,
      videoId: videoId,
      dio: dio,
    );
  } catch (_) {
    // Ön yükleme isteğe bağlı; oynatma sırasında tekrar denenir.
  } finally {
    await controller?.dispose();
  }
}
