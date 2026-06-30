import 'package:flutter/foundation.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';

import '../push/push_navigation_handler.dart';
import 'onesignal_config.dart';

typedef OneSignalTokenRefreshCallback = void Function();

/// OneSignal push SDK — Firebase FCM ile birlikte (Android teslimat kanalı).
class OneSignalBootstrap {
  OneSignalBootstrap._();

  static bool _ready = false;
  static String? _externalUserId;
  static OneSignalTokenRefreshCallback? onPushTokenChanged;

  static bool get isReady => _ready;

  /// Son [login] ile eşlenen kullanıcı kimliği (OneSignal external_id).
  static String? get externalUserId => _externalUserId;

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
        PushNavigationHandler.handleNotificationTap(
          event.notification.additionalData,
        );
      });

      OneSignal.Notifications.addForegroundWillDisplayListener((event) {
        final additional = event.notification.additionalData;
        final data = <String, dynamic>{
          if (additional != null)
            ...additional.map((k, v) => MapEntry(k.toString(), v)),
          if (event.notification.title != null)
            'title': event.notification.title!,
          if (event.notification.body != null)
            'body': event.notification.body!,
        };
        final isFortuneInvite = data.isNotEmpty &&
            PushNavigationHandler.handleFortuneInviteData(
              data,
              notifyReceived: false,
            );
        // preventDefault olmadan display() çağrılırsa Android'de çift bildirim oluşur.
        event.preventDefault();
        if (!isFortuneInvite) {
          event.notification.display();
          PushNavigationHandler.onPushReceived?.call();
        }
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
      _externalUserId = externalUserId;
      debugPrint('OneSignal login: $externalUserId');
    } catch (e) {
      debugPrint('OneSignal login failed: $e');
    }
  }

  static Future<void> logout() async {
    if (!_ready) return;
    try {
      await OneSignal.logout();
      _externalUserId = null;
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
