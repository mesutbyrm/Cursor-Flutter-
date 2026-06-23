/// Falcı davet popup'ını push/SSE sonrası zorla göstermek için köprü.
class PsychicInviteCoordinator {
  PsychicInviteCoordinator._();

  static void Function()? onRequestPresent;
  static String? _lastShownSessionId;
  static DateTime? _lastShownAt;
  static String? _lastPresentRequestId;
  static DateTime? _lastPresentRequestAt;

  static const _dedupeWindow = Duration(seconds: 60);

  static void requestPresent({String? sessionId}) {
    if (sessionId != null && sessionId.isNotEmpty) {
      if (_lastPresentRequestId == sessionId &&
          _lastPresentRequestAt != null &&
          DateTime.now().difference(_lastPresentRequestAt!) < _dedupeWindow) {
        return;
      }
      _lastPresentRequestId = sessionId;
      _lastPresentRequestAt = DateTime.now();
    }
    onRequestPresent?.call();
  }

  /// Dialog gösterildikten sonra aynı oturumu tekrar açmayı engeller.
  static bool shouldDebounceShown(String sessionId) {
    if (sessionId.isEmpty) return false;
    if (_lastShownSessionId != sessionId || _lastShownAt == null) return false;
    return DateTime.now().difference(_lastShownAt!) < _dedupeWindow;
  }

  static void markDialogShown(String sessionId) {
    _lastShownSessionId = sessionId;
    _lastShownAt = DateTime.now();
  }
}
