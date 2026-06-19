import 'package:flutter/foundation.dart';

/// Sentry entegrasyonu — `SENTRY_DSN` dart-define ile etkinleştirilir.
abstract final class SentryBootstrap {
  static var _enabled = false;

  static bool get isEnabled => _enabled;

  static Future<void> init() async {
    const dsn = String.fromEnvironment('SENTRY_DSN');
    if (dsn.isEmpty) {
      if (kDebugMode) {
        debugPrint('Sentry: skipped (set --dart-define=SENTRY_DSN=...)');
      }
      return;
    }
    // sentry_flutter paketi eklendiğinde burada SentryFlutter.init çağrılır.
    _enabled = true;
    if (kDebugMode) debugPrint('Sentry: DSN configured (init stub ready)');
  }

  static void captureException(Object error, {StackTrace? stackTrace}) {
    if (!_enabled) return;
    if (kDebugMode) debugPrint('Sentry capture: $error');
  }

  static void addBreadcrumb(String message) {
    if (!_enabled) return;
  }

  static Future<void> setUserId(String userId) async {
    if (!_enabled) return;
  }
}
