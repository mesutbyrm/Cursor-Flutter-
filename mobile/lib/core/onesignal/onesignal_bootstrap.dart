import 'package:flutter/foundation.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';

import '../push/push_navigation_handler.dart';
import 'onesignal_config.dart';

typedef OneSignalTokenRefreshCallback = void Function();

/// OneSignal push SDK — Firebase FCM ile birlikte (Android teslimat kanalı).
class OneSignalBootstrap {
  OneSignalBootstrap._();

  static bool _ready = false;
  static OneSignalTokenRefreshCallback? onPushTokenChanged;

  static bool get isReady => _ready;

  static Future<void> init() async {
    if (_ready || kIsWeb || !OneSignalConfig.enabled) return;

    try {
      if (kDebugMode) {
        OneSignal.Debug.setLogLevel(OSLogLevel.warn);
      }

      OneSignal.initialize(OneSignalConfig.appId);

      OneSignal.User.pushSubscription.addObserver((state) {
        final token = state.current.token;
        if (token != null && token.isNotEmpty) {
          debugPrint('OneSignal push token: ${token.substring(0, 12)}…');
          onPushTokenChanged?.call();
        }
      });

      OneSignal.Notifications.addClickListener((event) {
        PushNavigationHandler.handleAdditionalData(
          event.notification.additionalData,
        );
      });

      OneSignal.Notifications.addForegroundWillDisplayListener((event) {
        event.notification.display();
        PushNavigationHandler.onPushReceived?.call();
      });

      _ready = true;
      debugPrint('OneSignal: initialized');
    } catch (e, st) {
      debugPrint('OneSignal init failed: $e\n$st');
    }
  }

  /// Oturum açıldığında kullanıcıyı OneSignal’de eşle (external_id).
  static Future<void> login(String externalUserId) async {
    if (!_ready || externalUserId.isEmpty) return;
    try {
      await OneSignal.login(externalUserId);
      debugPrint('OneSignal login: $externalUserId');
    } catch (e) {
      debugPrint('OneSignal login failed: $e');
    }
  }

  static Future<void> logout() async {
    if (!_ready) return;
    try {
      await OneSignal.logout();
    } catch (e) {
      debugPrint('OneSignal logout failed: $e');
    }
  }

  /// Android’de genelde FCM token; sunucu kaydı için kullanılır.
  static String? get pushToken {
    if (!_ready) return null;
    final token = OneSignal.User.pushSubscription.token;
    if (token == null || token.isEmpty) return null;
    return token;
  }

  static bool get permissionGranted {
    if (!_ready) return false;
    return OneSignal.Notifications.permission;
  }

  static Future<bool> requestPermission({bool fallbackToSettings = false}) async {
    if (!_ready || kIsWeb) return false;
    try {
      return await OneSignal.Notifications.requestPermission(fallbackToSettings);
    } catch (e) {
      debugPrint('OneSignal requestPermission failed: $e');
      return false;
    }
  }
}
