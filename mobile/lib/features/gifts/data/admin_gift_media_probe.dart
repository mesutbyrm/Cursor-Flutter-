import 'dart:io';

import 'package:video_player/video_player.dart';
import 'package:video_thumbnail/video_thumbnail.dart';

/// MP4/WebM hediye dosyasından süre ve önizleme karesi çıkarır.
abstract final class AdminGiftMediaProbe {
  static Future<int?> durationMs(File file) async {
    final lower = file.path.toLowerCase();
    if (!lower.endsWith('.mp4') &&
        !lower.endsWith('.webm') &&
        !lower.endsWith('.mov')) {
      return null;
    }
    VideoPlayerController? controller;
    try {
      controller = VideoPlayerController.file(file);
      await controller.initialize();
      final ms = controller.value.duration.inMilliseconds;
      return ms > 0 ? ms : null;
    } catch (_) {
      return null;
    } finally {
      await controller?.dispose();
    }
  }

  /// Videodan JPEG kare üretir; statik hediye görseli yoksa kullanılır.
  static Future<File?> thumbnailFile(File video) async {
    try {
      final path = await VideoThumbnail.thumbnailFile(
        video: video.path,
        imageFormat: ImageFormat.JPEG,
        timeMs: 500,
        maxWidth: 512,
        quality: 88,
      );
      if (path == null || path.isEmpty) return null;
      final f = File(path);
      return await f.exists() ? f : null;
    } catch (_) {
      return null;
    }
  }
}
