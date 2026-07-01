import 'dart:async';
import 'dart:io';

import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:video_player/video_player.dart';

/// Kısa video ve sosyal video için disk önbelleği.
class VideoCacheService {
  VideoCacheService._();

  static final VideoCacheService instance = VideoCacheService._();

  final CacheManager _manager = CacheManager(
    Config(
      'canlifal_videos_v2',
      stalePeriod: const Duration(days: 7),
      maxNrOfCacheObjects: 48,
      fileService: HttpFileService(),
    ),
  );

  CacheManager get manager => _manager;

  Future<File?> peekCachedFile(String url) async {
    if (url.trim().isEmpty) return null;
    try {
      final info = await _manager.getFileFromCache(url);
      final file = info?.file;
      if (file != null && await file.exists()) return file;
    } catch (_) {}
    return null;
  }

  Future<File?> getCachedFile(String url) async {
    if (url.trim().isEmpty) return null;
    final cached = await peekCachedFile(url);
    if (cached != null) return cached;
    try {
      return await _manager.getSingleFile(url);
    } catch (_) {
      return null;
    }
  }

  Future<void> prefetch(String url) async {
    if (url.trim().isEmpty) return;
    try {
      await _manager.downloadFile(url);
    } catch (_) {}
  }

  Future<VideoPlayerController> createController(String url) async {
    final file = await getCachedFile(url);
    if (file != null && await file.exists()) {
      final c = VideoPlayerController.file(file);
      await c.initialize();
      return c;
    }
    final c = VideoPlayerController.networkUrl(Uri.parse(url));
    await c.initialize();
    unawaited(_manager.downloadFile(url));
    return c;
  }
}
