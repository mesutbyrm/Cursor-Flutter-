import 'dart:async';
import 'dart:io';

import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:video_player/video_player.dart';

/// Kısa video ve sosyal video için disk önbelleği + sıcak controller havuzu.
class VideoCacheService {
  VideoCacheService._();

  static final VideoCacheService instance = VideoCacheService._();

  static const _maxWarmControllers = 4;

  final CacheManager _manager = CacheManager(
    Config(
      'canlifal_videos_v2',
      stalePeriod: const Duration(days: 7),
      maxNrOfCacheObjects: 64,
      fileService: HttpFileService(),
    ),
  );

  final _warmControllers = <String, VideoPlayerController>{};
  final _warmOrder = <String>[];

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

  /// Hediye kuyruğu — dosyayı indir + controller'ı ısıt.
  Future<void> warmController(String url) async {
    if (url.trim().isEmpty) return;
    if (_warmControllers.containsKey(url)) return;
    try {
      final c = await createController(url);
      _putWarm(url, c);
    } catch (_) {}
  }

  VideoPlayerController? takeWarmController(String url) {
    final c = _warmControllers.remove(url);
    if (c != null) {
      _warmOrder.remove(url);
    }
    return c;
  }

  void releaseWarmController(String url, VideoPlayerController controller) {
    if (_warmControllers.containsKey(url)) {
      controller.dispose();
      return;
    }
    _putWarm(url, controller);
  }

  void _putWarm(String url, VideoPlayerController c) {
    while (_warmControllers.length >= _maxWarmControllers && _warmOrder.isNotEmpty) {
      final evict = _warmOrder.removeAt(0);
      _warmControllers.remove(evict)?.dispose();
    }
    _warmControllers[url] = c;
    _warmOrder.remove(url);
    _warmOrder.add(url);
  }

  Future<VideoPlayerController> createController(String url) async {
    final warm = takeWarmController(url);
    if (warm != null && warm.value.isInitialized) return warm;

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

  void disposeAllWarm() {
    for (final c in _warmControllers.values) {
      c.dispose();
    }
    _warmControllers.clear();
    _warmOrder.clear();
  }
}
