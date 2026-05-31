import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

/// Oda arka plan müziği — DJ API `musicUrl` ile senkron.
class VoiceRoomDjPlayer {
  VoiceRoomDjPlayer() : _player = AudioPlayer()..setReleaseMode(ReleaseMode.loop);

  final AudioPlayer _player;
  String? _currentUrl;

  Future<void> sync({String? musicUrl, required bool playing}) async {
    if (!playing || musicUrl == null || musicUrl.isEmpty) {
      await stop();
      return;
    }
    if (_currentUrl == musicUrl && _player.state == PlayerState.playing) {
      return;
    }
    try {
      _currentUrl = musicUrl;
      await _player.stop();
      await _player.play(UrlSource(musicUrl));
    } catch (e) {
      debugPrint('DJ play error: $e');
    }
  }

  Future<void> stop() async {
    _currentUrl = null;
    try {
      await _player.stop();
    } catch (_) {}
  }

  void dispose() {
    _player.dispose();
  }
}
