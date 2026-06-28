import 'package:audioplayers/audioplayers.dart';

import '../../../../core/config/env.dart';
import '../utils/voice_sse_dj_payload.dart';

/// SSE DJ olaylarında doğrudan `musicUrl` oynatma — `audioplayers` yedek katmanı.
class VoiceRoomSseAudioPlayer {
  VoiceRoomSseAudioPlayer() : _player = AudioPlayer();

  final AudioPlayer _player;
  String? _lastUrl;

  Future<void> handleDjEvent(Map<String, dynamic> event) async {
    final playing = voiceSseDjIsPlaying(event);
    final musicUrl = event['musicUrl']?.toString().trim();
    if (playing && musicUrl != null && musicUrl.isNotEmpty && _canPlayDirect(musicUrl)) {
      final resolved = _resolveUrl(musicUrl);
      if (resolved == _lastUrl && _player.state == PlayerState.playing) return;
      _lastUrl = resolved;
      try {
        await _player.play(UrlSource(resolved));
      } catch (_) {}
      return;
    }
    if (!playing) {
      _lastUrl = null;
      try {
        await _player.stop();
      } catch (_) {}
    }
  }

  bool _canPlayDirect(String url) {
    if (url.contains('youtube-stream') || url.contains('youtube.com/watch')) {
      return false;
    }
    return url.startsWith('http://') ||
        url.startsWith('https://') ||
        url.startsWith('/');
  }

  String _resolveUrl(String url) {
    if (url.startsWith('http://') || url.startsWith('https://')) return url;
    if (url.startsWith('/')) {
      final base = Env.siteOrigin.replaceAll(RegExp(r'/$'), '');
      return '$base$url';
    }
    return url;
  }

  Future<void> dispose() async {
    _lastUrl = null;
    try {
      await _player.stop();
    } catch (_) {}
    try {
      await _player.dispose();
    } catch (_) {}
  }
}
