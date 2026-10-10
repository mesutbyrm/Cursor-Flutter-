/// Push teslimat modu — varsayılan: yalnızca FCM (OneSignal SDK kapalı).
abstract final class PushConfig {
  /// `true` (varsayılan): OneSignal başlatılmaz; token ve bildirimler FCM üzerinden.
  /// Geçici geri dönüş: `--dart-define=USE_FCM_ONLY=false`
  static const bool useFcmOnly = bool.fromEnvironment(
    'USE_FCM_ONLY',
    defaultValue: true,
  );
}
