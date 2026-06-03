import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

import '../../data/youtube_stream_resolver.dart';

/// Oda arka plan müziği — DJ API `musicUrl` ile senkron.
class VoiceRoomDjPlayer {
  VoiceRoomDjPlayer(this._resolver)
      : _player = AudioPlayer()..setReleaseMode(ReleaseMode.stop) {
    _player.onPlayerComplete.listen((_) {
      onTrackComplete?.call();
    });
    _player.onDurationChanged.listen((d) {
      playback.value = VoiceRoomDjPlayback(
        position: playback.value.position,
        duration: d,
        playing: playback.value.playing,
      );
    });
    _player.onPositionChanged.listen((p) {
      playback.value = VoiceRoomDjPlayback(
        position: p,
        duration: playback.value.duration,
        playing: playback.value.playing,
      );
    });
    _player.onPlayerStateChanged.listen((s) {
      playback.value = VoiceRoomDjPlayback(
        position: playback.value.position,
        duration: playback.value.duration,
        playing: s == PlayerState.playing,
      );
    });
  }

  final YoutubeStreamResolver _resolver;
  final AudioPlayer _player;
  final ValueNotifier<VoiceRoomDjPlayback> playback =
      ValueNotifier(const VoiceRoomDjPlayback());
  String? _currentUrl;
  void Function()? onTrackComplete;

  Future<void> sync({
    String? musicUrl,
    required bool playing,
    bool muted = false,
  }) async {
    if (muted || !playing || musicUrl == null || musicUrl.isEmpty) {
      await stop();
      return;
    }

    var source = musicUrl;
    if (_resolver.needsResolve(musicUrl)) {
      final resolved = await _resolver.resolvePlayableUrl(musicUrl);
      if (resolved == null || resolved.isEmpty) {
        debugPrint('DJ: YouTube akışı çözülemedi: $musicUrl');
        return;
      }
      source = resolved;
    }

    if (_currentUrl == source && _player.state == PlayerState.playing) {
      return;
    }
    try {
      _currentUrl = source;
      await _player.stop();
      await _player.play(UrlSource(source));
      playback.value = VoiceRoomDjPlayback(
        position: Duration.zero,
        duration: playback.value.duration,
        playing: true,
      );
    } catch (e) {
      debugPrint('DJ play error: $e');
      _currentUrl = null;
    }
  }

  Future<void> stop() async {
    _currentUrl = null;
    try {
      await _player.stop();
      playback.value = const VoiceRoomDjPlayback();
    } catch (_) {}
  }

  void dispose() {
    onTrackComplete = null;
    playback.dispose();
    _player.dispose();
  }
}

class VoiceRoomDjPlayback {
  const VoiceRoomDjPlayback({
    this.position = Duration.zero,
    this.duration = Duration.zero,
    this.playing = false,
  });

  final Duration position;
  final Duration duration;
  final bool playing;

  double get progress {
    if (duration.inMilliseconds <= 0) return 0;
    return (position.inMilliseconds / duration.inMilliseconds).clamp(0.0, 1.0);
  }

  Duration get remaining {
    if (duration <= position) return Duration.zero;
    return duration - position;
  }
}
