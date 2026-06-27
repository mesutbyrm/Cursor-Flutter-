/// Sesli oda — temel mod: SSE, müzik, moderasyon ve premium (web parity).
///
/// `--dart-define=VOICE_ROOM_FULL=true` → tam RTC sayfası (`VoiceRoomRtcPage`).
class VoiceRoomBasicMode {
  VoiceRoomBasicMode._();

  static const _full = bool.fromEnvironment('VOICE_ROOM_FULL', defaultValue: false);

  /// `true` → `VoiceRoomBasicPage` (web parity istemci; backend değişmez).
  static bool get enabled => !_full;

  /// Temel sayfada web parity müzik (!istek, kuyruk, DJ, mini player).
  static bool get musicEnabled => enabled;

  /// Hediye, PK, sohbet, efekt, tema — mevcut canlifal.com API/SSE ile.
  static bool get premiumEnabled => enabled;
}
