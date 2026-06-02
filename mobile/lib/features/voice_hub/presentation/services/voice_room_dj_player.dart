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
  }

  final YoutubeStreamResolver _resolver;
  final AudioPlayer _player;
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
    } catch (e) {
      debugPrint('DJ play error: $e');
      _currentUrl = null;
    }
  }

  Future<void> stop() async {
    _currentUrl = null;
    try {
      await _player.stop();
    } catch (_) {}
  }

  void dispose() {
    onTrackComplete = null;
    _player.dispose();
  }
}
