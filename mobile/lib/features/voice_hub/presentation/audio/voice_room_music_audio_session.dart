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

  static Future<void> activateForPlayback() async {
    if (kIsWeb) return;
    if (!_configured) await ensureConfigured();
    try {
      final session = await AudioSession.instance;
      await session.setActive(true);
    } catch (e) {
      debugPrint('VoiceRoomMusicAudioSession activate: $e');
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
