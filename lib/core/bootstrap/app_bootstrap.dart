import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class AppBootstrap {
  static Future<void> initialize() async {
    try {
      await Firebase.initializeApp();
    } on Object {
      // Firebase yapılandırması ortama göre native projelerde sağlanır.
    }
    await PushNotificationService().initialize();
  }
}

class PushNotificationService {
  PushNotificationService({FlutterLocalNotificationsPlugin? localNotifications})
    : _localNotifications =
          localNotifications ?? FlutterLocalNotificationsPlugin();

  final FlutterLocalNotificationsPlugin _localNotifications;

  Future<void> initialize() async {
    const InitializationSettings settings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      iOS: DarwinInitializationSettings(),
    );
    await _localNotifications.initialize(settings: settings);
    try {
      if (Firebase.apps.isNotEmpty) {
        await FirebaseMessaging.instance.requestPermission();
        await FirebaseMessaging.instance.getToken();
      }
    } on Object {
      return;
    }
  }
}
