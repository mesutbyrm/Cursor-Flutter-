import 'package:audio_session/audio_session.dart';
import 'package:flutter/foundation.dart';

/// Sesli oda + DJ müziği — TRTC/LiveKit ile aynı anda çalabilsin diye
/// `AudioSessionConfiguration.music()` + `mixWithOthers`.
class VoiceRoomMusicAudioSession {
  static var _configured = false;

  static Future<void> ensureConfigured() async {
    if (kIsWeb) return;
    try {
      final session = await AudioSession.instance;
      await session.configure(
        const AudioSessionConfiguration.music().copyWith(
          avAudioSessionCategoryOptions:
              AVAudioSessionCategoryOptions.mixWithOthers,
          // TRTC/LiveKit ile aynı anda çalabilsin; transient duck müziği susturuyordu.
          androidAudioFocusGainType: AndroidAudioFocusGainType.gain,
          androidWillPauseWhenDucked: false,
        ),
      );
      _configured = true;
      debugPrint(
        'VoiceRoomMusicAudioSession: configured (gain + mixWithOthers)',
      );
    } catch (e) {
      debugPrint('VoiceRoomMusicAudioSession configure: $e');
    }
  }

  static Future<void> activateForPlayback({int maxAttempts = 3}) async {
    if (kIsWeb) return;
    if (!_configured) await ensureConfigured();
    for (var attempt = 1; attempt <= maxAttempts; attempt++) {
      try {
        final session = await AudioSession.instance;
        await session.setActive(true);
        debugPrint('VoiceRoomMusicAudioSession: active (attempt $attempt)');
        return;
      } catch (e) {
        debugPrint('VoiceRoomMusicAudioSession activate attempt $attempt: $e');
      }
      if (attempt < maxAttempts) {
        await Future<void>.delayed(Duration(milliseconds: 180 * attempt));
      }
    }
  }

  static Future<void> deactivate() async {
    if (kIsWeb) return;
    try {
      final session = await AudioSession.instance;
      await session.setActive(false);
    } catch (_) {}
  }
}
