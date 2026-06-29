import 'package:flutter_tts/flutter_tts.dart';

import '../../domain/entities/fortune_type_entity.dart' show FortuneReadingResult;

/// Fal sonucu — sesli okuma (TTS).
class FortuneResultSpeech {
  FortuneResultSpeech._();

  static final FlutterTts _tts = FlutterTts();
  static var _ready = false;
  static var _speaking = false;

  static Future<void> _ensureReady() async {
    if (_ready) return;
    await _tts.setLanguage('tr-TR');
    await _tts.setSpeechRate(0.48);
    await _tts.setPitch(1.0);
    await _tts.setVolume(1.0);
    _tts.setCompletionHandler(() => _speaking = false);
    _tts.setCancelHandler(() => _speaking = false);
    _ready = true;
  }

  static bool get isSpeaking => _speaking;

  static Future<void> speak(FortuneReadingResult result) async {
    await _ensureReady();
    if (_speaking) {
      await stop();
      return;
    }
    final buffer = StringBuffer();
    if (result.summary.trim().isNotEmpty) {
      buffer.writeln(result.summary.trim());
    }
    for (final section in result.sections) {
      if (section.body.trim().isEmpty) continue;
      buffer.writeln(section.body.trim());
    }
    if (buffer.isEmpty && result.detail.trim().isNotEmpty) {
      buffer.write(result.detail.trim());
    }
    final text = buffer.toString().trim();
    if (text.isEmpty) return;
    _speaking = true;
    await _tts.speak(text);
  }

  static Future<void> stop() async {
    await _tts.stop();
    _speaking = false;
  }
}
