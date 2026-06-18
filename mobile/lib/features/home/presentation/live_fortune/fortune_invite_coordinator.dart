/// Falcı davet popup'ını push/SSE sonrası zorla göstermek için köprü.
class FortuneInviteCoordinator {
  FortuneInviteCoordinator._();

  static void Function()? onRequestPresent;
  static String? _lastShownSessionId;
  static DateTime? _lastShownAt;

  static void requestPresent({String? sessionId}) {
    onRequestPresent?.call();
  }

  /// Dialog gösterildikten sonra kısa süre aynı oturumu tekrar açmayı engeller.
  static bool shouldDebounceShown(String sessionId) {
    if (sessionId.isEmpty) return false;
    if (_lastShownSessionId != sessionId || _lastShownAt == null) return false;
    return DateTime.now().difference(_lastShownAt!) <
        const Duration(seconds: 3);
  }

  static void markDialogShown(String sessionId) {
    _lastShownSessionId = sessionId;
    _lastShownAt = DateTime.now();
  }
}
