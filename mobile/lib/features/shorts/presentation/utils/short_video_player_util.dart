import 'dart:async';

import 'package:dio/dio.dart';
import 'package:video_player/video_player.dart';

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
  for (final playUrl in candidates) {
    if (playUrl.isEmpty) continue;
    VideoPlayerController? controller;
    try {
      controller = VideoPlayerController.networkUrl(Uri.parse(playUrl));
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
