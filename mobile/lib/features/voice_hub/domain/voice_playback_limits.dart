/// Oda müziği / video — web ile aynı 6 dakika üst sınırı.
abstract final class VoicePlaybackLimits {
  static const maxPlaybackDuration = Duration(minutes: 6);
  static const maxPlaybackMs = 360000;

  static Duration clampPosition(Duration position) {
    if (position > maxPlaybackDuration) return maxPlaybackDuration;
    return position;
  }

  static int clampPositionMs(int ms) {
    if (ms > maxPlaybackMs) return maxPlaybackMs;
    return ms;
  }
}
