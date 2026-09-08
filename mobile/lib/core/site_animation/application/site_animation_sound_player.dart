import 'dart:async';

import 'package:just_audio/just_audio.dart';

/// Site animation SFX — katalog `soundUrl` veya tier varsayılanı.
abstract final class SiteAnimationSoundPlayer {
  static final AudioPlayer _player = AudioPlayer();
  static String? _lastUrl;

  static Future<void> preload(String? url) async {
    final u = url?.trim();
    if (u == null || u.isEmpty) return;
    if (_lastUrl == u) return;
    try {
      if (u.startsWith('http')) {
        await _player.setUrl(u);
      } else {
        final asset = u.startsWith('assets/') ? u.substring(7) : u;
        await _player.setAsset(asset);
      }
      _lastUrl = u;
    } catch (_) {}
  }

  static Future<void> play(String? url) async {
    final u = url?.trim();
    if (u == null || u.isEmpty) return;
    try {
      if (_lastUrl != u) {
        await preload(u);
      }
      await _player.seek(Duration.zero);
      await _player.play();
    } catch (_) {}
  }

  static Future<void> dispose() async {
    await _player.dispose();
    _lastUrl = null;
  }
}
