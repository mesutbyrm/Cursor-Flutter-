import 'dart:async';

import 'package:dio/dio.dart';
import 'package:video_player/video_player.dart';

import '../domain/entities/short_video_entity.dart';
import '../presentation/utils/short_video_player_util.dart';

/// En fazla 5 oynatıcı — aktif ±2 video bellekte; yeniden initialize yok.
class ShortsVideoControllerPool {
  ShortsVideoControllerPool(this._dio);

  final Dio _dio;
  static const _maxControllers = 5;
  static const _warmOffsets = [-1, 0, 1, 2];

  final _controllers = <String, VideoPlayerController>{};
  final _pending = <String, Future<VideoPlayerController>>{};
  String? _activeId;

  VideoPlayerController? controllerFor(String videoId) =>
      _controllers[videoId];

  Future<VideoPlayerController> acquire(ShortVideoEntity video) async {
    final id = video.id;
    final existing = _controllers[id];
    if (existing != null && existing.value.isInitialized) {
      return existing;
    }
    final inflight = _pending[id];
    if (inflight != null) return inflight;

    final future = createShortVideoController(
      url: video.videoUrl,
      videoId: id,
      dio: _dio,
      fastStart: true,
    ).then((c) {
      _controllers[id] = c;
      _pending.remove(id);
      _trimPool();
      return c;
    }).catchError((Object e) {
      _pending.remove(id);
      throw e;
    });

    _pending[id] = future;
    return future;
  }

  Future<void> warm(List<ShortVideoEntity> videos, int index) async {
    if (videos.isEmpty) return;
    final keep = <String>{};
    for (final offset in _warmOffsets) {
      final i = index + offset;
      if (i < 0 || i >= videos.length) continue;
      final v = videos[i];
      keep.add(v.id);
      unawaited(acquire(v).catchError((_) {}));
    }
    _evictExcept(keep);
    for (final offset in [-2, -1, 0, 1, 2, 3]) {
      final i = index + offset;
      if (i < 0 || i >= videos.length) continue;
      unawaited(
        preloadShortVideoUrl(
          videos[i].videoUrl,
          videoId: videos[i].id,
          dio: _dio,
        ),
      );
    }
  }

  void setActive(String? videoId, {double playbackSpeed = 1.0}) {
    _activeId = videoId;
    for (final entry in _controllers.entries) {
      final c = entry.value;
      if (!c.value.isInitialized) continue;
      if (entry.key == videoId) {
        c.setPlaybackSpeed(playbackSpeed);
        c.play();
      } else {
        c.pause();
      }
    }
  }

  void _trimPool() {
    if (_controllers.length <= _maxControllers) return;
    final victims = _controllers.keys
        .where((id) => id != _activeId)
        .take(_controllers.length - _maxControllers)
        .toList();
    for (final id in victims) {
      _controllers.remove(id)?.dispose();
    }
  }

  void _evictExcept(Set<String> keep) {
    final remove = _controllers.keys.where((id) => !keep.contains(id)).toList();
    for (final id in remove) {
      if (id == _activeId) continue;
      _controllers.remove(id)?.dispose();
    }
  }

  void disposeAll() {
    for (final c in _controllers.values) {
      c.dispose();
    }
    _controllers.clear();
    _pending.clear();
    _activeId = null;
  }
}
