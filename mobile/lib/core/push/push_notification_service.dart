import 'dart:convert';
import 'dart:io';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';

import 'push_navigation_handler.dart';

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
            AndroidFlutterLocalNotificationsPlugin
          >()
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
            AndroidFlutterLocalNotificationsPlugin
          >()
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

  Future<bool> refreshPermissionStatus() async {
    if (kIsWeb) return false;

    try {
      if (Platform.isAndroid) {
        final status = await Permission.notification.status;
        _permissionGranted = status.isGranted;
        return _permissionGranted;
      }

      final settings = await FirebaseMessaging.instance
          .getNotificationSettings();
      _permissionGranted =
          settings.authorizationStatus == AuthorizationStatus.authorized ||
          settings.authorizationStatus == AuthorizationStatus.provisional;
      return _permissionGranted;
    } catch (e) {
      debugPrint('Notification permission status failed: $e');
      return _permissionGranted;
    }
  }

  void _onTap(NotificationResponse response) {
    final payload = response.payload?.trim();
    if (payload == null || payload.isEmpty) return;
    if (payload.startsWith('{')) {
      try {
        final decoded = jsonDecode(payload);
        if (decoded is Map) {
          PushNavigationHandler.handleNotificationTap(
            decoded.map((k, v) => MapEntry(k.toString(), v)),
          );
        }
      } catch (_) {}
      return;
    }
    PushNavigationHandler.navigateToPath(payload);
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
    await bindOpenedAppHandlers(messaging);
  }

  Future<void> bindOpenedAppHandlers(FirebaseMessaging messaging) async {
    FirebaseMessaging.onMessageOpenedApp.listen((msg) {
      PushNavigationHandler.handleNotificationTap(msg.data);
    });
    final initial = await messaging.getInitialMessage();
    if (initial != null) {
      PushNavigationHandler.handleNotificationTap(initial.data);
    }
  }

  Future<void> showRemoteMessage(RemoteMessage msg) async {
    if (!_initialized) await init();

    final data = Map<String, dynamic>.from(msg.data);
    if (PushNavigationHandler.handleFortuneInviteData(
      data,
      notifyReceived: false,
    )) {
      return;
    }

    final title =
        msg.notification?.title ?? msg.data['title']?.toString() ?? 'Canlifal';
    final body =
        msg.notification?.body ??
        msg.data['body']?.toString() ??
        msg.data['message']?.toString();
    final type = data['type']?.toString().toLowerCase() ?? '';
    final isMessage = type.contains('message') ||
        type.contains('chat') ||
        data['conversationId'] != null ||
        data['senderId'] != null;
    final payload = data.isNotEmpty
        ? jsonEncode(data)
        : msg.data['targetPath']?.toString();

    final android = AndroidNotificationDetails(
      isMessage ? _urgentChannelId : _channelId,
      isMessage ? 'Canlifal — Acil' : _channelName,
      channelDescription:
          isMessage ? 'Mesaj ve sohbet bildirimleri' : 'Canlifal bildirimleri',
      importance: isMessage ? Importance.max : Importance.high,
      priority: isMessage ? Priority.max : Priority.high,
      category: isMessage ? AndroidNotificationCategory.message : null,
      icon: '@mipmap/ic_launcher',
    );
    const ios = DarwinNotificationDetails();

    await _local.show(
      msg.hashCode,
      title,
      body,
      NotificationDetails(android: android, iOS: ios),
      payload: payload,
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

  /// Yerel bildirim — gelen arama vb.
  Future<void> showLocal({
    required int id,
    required String title,
    required String body,
    String? payload,
    bool urgent = false,
  }) async {
    if (!_initialized) await init();
    final channelId = urgent ? _urgentChannelId : _channelId;
    final channelName = urgent ? 'Canlifal — Acil' : _channelName;
    final android = AndroidNotificationDetails(
      channelId,
      channelName,
      importance: urgent ? Importance.max : Importance.high,
      priority: urgent ? Priority.max : Priority.high,
      fullScreenIntent: urgent,
      category: urgent ? AndroidNotificationCategory.call : null,
      icon: '@mipmap/ic_launcher',
    );
    const ios = DarwinNotificationDetails(
      presentAlert: true,
      presentSound: true,
    );
    await _local.show(
      id,
      title,
      body,
      NotificationDetails(android: android, iOS: ios),
      payload: payload,
    );
  }
}
