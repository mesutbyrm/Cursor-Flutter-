/// Oturum açılmadan gelen deep link / push hedefi — login sonrası devam.
abstract final class PostLoginNavigation {
  static String? _pendingPath;

  static void remember(String path) {
    final trimmed = path.trim();
    if (trimmed.isEmpty) return;
    _pendingPath = trimmed.startsWith('/') ? trimmed : '/$trimmed';
  }

  static String? takePending() {
    final path = _pendingPath;
    _pendingPath = null;
    return path;
  }

  static bool get hasPending => _pendingPath != null && _pendingPath!.isNotEmpty;
}
