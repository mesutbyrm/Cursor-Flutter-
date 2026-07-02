import 'dart:async';

import 'package:dio/dio.dart';
import 'package:video_player/video_player.dart';

import '../domain/entities/short_video_entity.dart';
import '../presentation/utils/short_video_player_util.dart';

/// Aktif ±1 video bellekte (max 3 controller); uzaktakiler dispose.
class ShortsVideoControllerPool {
  ShortsVideoControllerPool(this._dio);

  final Dio _dio;
  static const _maxControllers = 3;
  static const _warmOffsets = [-1, 0, 1];

  final _controllers = <String, VideoPlayerController>{};
  final _pending = <String, Future<VideoPlayerController>>{};
  final _lastUsed = <String, int>{};
  String? _activeId;
  var _tick = 0;

  VideoPlayerController? controllerFor(String videoId) =>
      _controllers[videoId];

  Future<VideoPlayerController> acquire(ShortVideoEntity video) async {
    final id = video.id;
    _touch(id);

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
      _touch(id);
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
      unawaited(() async {
        try {
          await acquire(v);
        } catch (_) {}
      }());
    }
    _evictExcept(keep);

    for (final offset in [-1, 0, 1, 2]) {
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
    if (videoId != null) _touch(videoId);

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

  void _touch(String id) {
    _lastUsed[id] = ++_tick;
  }

  void _trimPool() {
    if (_controllers.length <= _maxControllers) return;
    final sorted = _controllers.keys.toList()
      ..sort((a, b) => (_lastUsed[a] ?? 0).compareTo(_lastUsed[b] ?? 0));
    for (final id in sorted) {
      if (_controllers.length <= _maxControllers) break;
      if (id == _activeId) continue;
      _controllers.remove(id)?.dispose();
      _lastUsed.remove(id);
    }
  }

  void _evictExcept(Set<String> keep) {
    final remove = _controllers.keys.where((id) => !keep.contains(id)).toList();
    for (final id in remove) {
      if (id == _activeId) continue;
      _controllers.remove(id)?.dispose();
      _lastUsed.remove(id);
    }
  }

  void disposeAll() {
    for (final c in _controllers.values) {
      c.dispose();
    }
    _controllers.clear();
    _pending.clear();
    _lastUsed.clear();
    _activeId = null;
  }
}
