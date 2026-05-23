import 'dart:io';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';

/// Uygulama içi + sistem bildirimleri (FCM foreground ve izinler).
class PushNotificationService {
  PushNotificationService._();

  static final PushNotificationService instance = PushNotificationService._();

  static const _channelId = 'canlifal_default';
  static const _urgentChannelId = 'canlifal_urgent';
  static const _channelName = 'Canlifal';

  final FlutterLocalNotificationsPlugin _local =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;
  bool _permissionGranted = false;

  bool get permissionGranted => _permissionGranted;

  Future<void> init() async {
    if (_initialized) return;

    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    await _local.initialize(
      const InitializationSettings(android: android, iOS: ios),
      onDidReceiveNotificationResponse: _onTap,
    );

    if (!kIsWeb && Platform.isAndroid) {
      await _local
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(
            const AndroidNotificationChannel(
              _channelId,
              _channelName,
              description: 'Canlifal bildirimleri',
              importance: Importance.high,
            ),
          );
      await _local
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(
            const AndroidNotificationChannel(
              _urgentChannelId,
              'Canlifal — Acil',
              description: 'Mesaj, ödeme ve canlı yayın bildirimleri',
              importance: Importance.max,
            ),
          );
    }

    _initialized = true;
  }

  void _onTap(NotificationResponse response) {
    debugPrint('Local notification tap: ${response.payload}');
  }

  /// Android 13+ ve iOS bildirim izni.
  Future<bool> requestSystemPermission() async {
    if (kIsWeb) return false;

    if (Platform.isAndroid) {
      final status = await Permission.notification.request();
      _permissionGranted = status.isGranted;
      return _permissionGranted;
    }

    final messaging = FirebaseMessaging.instance;
    final settings = await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    _permissionGranted =
        settings.authorizationStatus == AuthorizationStatus.authorized ||
            settings.authorizationStatus == AuthorizationStatus.provisional;
    return _permissionGranted;
  }

  Future<void> bindForegroundFcm(FirebaseMessaging messaging) async {
    FirebaseMessaging.onMessage.listen((msg) async {
      await showRemoteMessage(msg);
    });
    FirebaseMessaging.onMessageOpenedApp.listen((msg) {
      debugPrint('FCM opened app: ${msg.data}');
    });
  }

  Future<void> showRemoteMessage(RemoteMessage msg) async {
    if (!_initialized) await init();

    final title = msg.notification?.title ??
        msg.data['title']?.toString() ??
        'Canlifal';
    final body = msg.notification?.body ??
        msg.data['body']?.toString() ??
        msg.data['message']?.toString();

    final android = AndroidNotificationDetails(
      _channelId,
      _channelName,
      channelDescription: 'Canlifal bildirimleri',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );
    const ios = DarwinNotificationDetails();

    await _local.show(
      msg.hashCode,
      title,
      body,
      NotificationDetails(android: android, iOS: ios),
      payload: msg.data['targetPath']?.toString(),
    );
  }

  Future<String?> currentFcmToken() async {
    if (kIsWeb) return null;
    try {
      return await FirebaseMessaging.instance.getToken();
    } catch (e) {
      debugPrint('FCM getToken failed: $e');
      return null;
    }
  }
}
