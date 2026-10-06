/// Spec 20 — uygulama arka plan / ön plan sesli oda davranışı (sözleşme).
abstract final class VoiceRoomBackgroundRecoverySpec {
  /// Uzun arka planda otomatik `leaveRoomSession` (`app_background`).
  static const backgroundSeatRelease = Duration(seconds: 45);

  /// SSE hub ön plana dönüş debounce (`SseHubLifecycleBinding`).
  static const sseHubResumeDebounce = Duration(milliseconds: 450);

  static const leaveSourceBackground = 'app_background';
  static const leaveSourceDetached = 'app_detached';

  /// Ön plana dönünce controller çağrısı — koltuk/PK/müzik REST senkronu.
  static const foregroundResyncMethod = 'resyncAfterSseReconnect';
}
