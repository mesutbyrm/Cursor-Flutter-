/// Falcı davet popup'ını push/SSE sonrası zorla göstermek için köprü.
class FortuneInviteCoordinator {
  FortuneInviteCoordinator._();

  static void Function()? onRequestPresent;
  static String? _lastSessionId;
  static DateTime? _lastRequestAt;

  /// Aynı oturum için kısa sürede tekrar popup açmayı engeller.
  static void requestPresent({String? sessionId}) {
    if (sessionId != null && sessionId.isNotEmpty) {
      final now = DateTime.now();
      if (_lastSessionId == sessionId &&
          _lastRequestAt != null &&
          now.difference(_lastRequestAt!) < const Duration(seconds: 4)) {
        return;
      }
      _lastSessionId = sessionId;
      _lastRequestAt = now;
    }
    onRequestPresent?.call();
  }

  static void markDialogShown(String sessionId) {
    _lastSessionId = sessionId;
    _lastRequestAt = DateTime.now();
  }
}
