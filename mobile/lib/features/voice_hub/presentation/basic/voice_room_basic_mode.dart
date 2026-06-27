/// Sesli oda — aşama 1: yalnızca temel akış (liste, giriş/çıkış, mic, hoparlör, katılımcılar, sahip).
///
/// İleride `--dart-define=VOICE_ROOM_FULL=true` ile tam web parity UI açılabilir.
class VoiceRoomBasicMode {
  VoiceRoomBasicMode._();

  static const _full = bool.fromEnvironment('VOICE_ROOM_FULL', defaultValue: false);

  /// `true` → temel oda sayfası ve hafif presence oturumu.
  static bool get enabled => !_full;
}
