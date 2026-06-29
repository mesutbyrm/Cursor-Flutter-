import 'package:audioplayers/audioplayers.dart';

/// Fal açılışı — mistik ambient müzik (düşük ses, döngü).
class FortuneAmbientAudio {
  FortuneAmbientAudio._();

  static final AudioPlayer _player = AudioPlayer();
  static var _playing = false;

  /// Pixabay — telifsiz mistik ambient (ağ yedek).
  static const _ambientUrl =
      'https://cdn.pixabay.com/download/audio/2022/03/24/audio_1286360763.mp3';

  static Future<void> playOpening() async {
    if (_playing) return;
    try {
      await _player.setReleaseMode(ReleaseMode.loop);
      await _player.setVolume(0.32);
      await _player.play(UrlSource(_ambientUrl));
      _playing = true;
    } catch (_) {
      _playing = false;
    }
  }

  static Future<void> stop() async {
    if (!_playing) return;
    try {
      await _player.stop();
    } catch (_) {}
    _playing = false;
  }

  static Future<void> fadeOutAndStop() async {
    if (!_playing) return;
    try {
      for (var v = 0.32; v > 0; v -= 0.08) {
        await _player.setVolume(v.clamp(0.0, 1.0));
        await Future<void>.delayed(const Duration(milliseconds: 80));
      }
      await _player.stop();
    } catch (_) {}
    _playing = false;
  }
}
