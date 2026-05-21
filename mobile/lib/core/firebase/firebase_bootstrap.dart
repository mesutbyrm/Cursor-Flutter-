import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

import 'firebase_options.dart';

/// Arka planda gelen FCM (uygulama kapalıyken).
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  if (!DefaultFirebaseOptions.enabled) return;
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  debugPrint('FCM background: ${message.messageId}');
}

/// Firebase init — yapılandırma yoksa sessizce atlanır (CI güvenli).
class FirebaseBootstrap {
  FirebaseBootstrap._();

  static bool _ready = false;

  static bool get isReady => _ready;

  static FirebaseAnalytics? analytics;
  static FirebaseMessaging? messaging;

  static Future<void> init() async {
    if (_ready) return;
    if (!DefaultFirebaseOptions.enabled) {
      debugPrint(
        'Firebase: skipped (set --dart-define=FIREBASE_PROJECT_ID=... etc.)',
      );
      return;
    }

    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

      analytics = FirebaseAnalytics.instance;
      messaging = FirebaseMessaging.instance;

      if (!kIsWeb) {
        await messaging!.requestPermission(
          alert: true,
          badge: true,
          sound: true,
        );
        final token = await messaging!.getToken();
        if (token != null) {
          debugPrint('FCM token: ${token.substring(0, 12)}…');
        }
      }

      FirebaseMessaging.onMessage.listen((msg) {
        debugPrint('FCM foreground: ${msg.notification?.title}');
      });

      _ready = true;
      await analytics!.logAppOpen();
    } catch (e, st) {
      debugPrint('Firebase init failed: $e\n$st');
    }
  }

  static Future<void> logEvent(
    String name, {
    Map<String, Object>? parameters,
  }) async {
    if (!_ready || analytics == null) return;
    try {
      await analytics!.logEvent(name: name, parameters: parameters);
    } catch (e) {
      debugPrint('Analytics logEvent failed: $e');
    }
  }
}
