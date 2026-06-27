/// Sesli oda — aşama 1: temel akış; aşama 2: SSE; aşama 3: müzik (web parity).
///
/// `--dart-define=VOICE_ROOM_FULL=true` → tam RTC sayfası (`VoiceRoomRtcPage`).
class VoiceRoomBasicMode {
  VoiceRoomBasicMode._();

  static const _full = bool.fromEnvironment('VOICE_ROOM_FULL', defaultValue: false);

  /// `true` → `VoiceRoomBasicPage` (temel + müzik; hediye/PK/video yok).
  static bool get enabled => !_full;

  /// Temel sayfada web parity müzik (!istek, kuyruk, DJ, mini player).
  static bool get musicEnabled => enabled;
}
