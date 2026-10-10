import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:ui' show DartPluginRegistrant;

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../features/notifications/data/local_notification_store.dart';
import 'push_delivery.dart';
import 'message_notification_data.dart';
import 'notification_channels.dart';
import 'notification_reply_sender.dart';
import 'push_navigation_handler.dart';

/// Uygulama kapalı/arka plandayken bildirim aksiyonu (Yanıtla) — ayrı isolate.
@pragma('vm:entry-point')
void notificationActionBackground(NotificationResponse response) {
  DartPluginRegistrant.ensureInitialized();
  PushNotificationService.handleBackgroundResponse(response);
}

/// Uygulama içi + sistem bildirimleri (FCM foreground ve izinler).
class PushNotificationService {
  PushNotificationService._();

  static final PushNotificationService instance = PushNotificationService._();

  /// Mesaj bildirimindeki "Yanıtla" aksiyonu / iOS kategorisi.
  static const replyActionId = 'canlifal_reply';
  static const messageCategoryId = 'canlifal_message';

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
    final ios = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
      notificationCategories: [
        DarwinNotificationCategory(
          messageCategoryId,
          actions: [
            // iOS: UNTextInputNotificationAction — bildirimden doğrudan yanıt.
            DarwinNotificationAction.text(
              replyActionId,
              'Yanıtla',
              buttonTitle: 'Gönder',
              placeholder: 'Mesaj yaz…',
            ),
          ],
        ),
      ],
    );
    await _local.initialize(
      InitializationSettings(android: android, iOS: ios),
      onDidReceiveNotificationResponse: _onTap,
      onDidReceiveBackgroundNotificationResponse: notificationActionBackground,
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
      // Kullanıcının açıp kapatabildiği 4 kanal (Mesajlar, Canlı yayın
      // başlatanlar, Günlük fal önerisi, Diğer).
      final androidImpl = _local
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();
      for (final c in AppNotificationChannel.values) {
        await androidImpl?.createNotificationChannel(
          AndroidNotificationChannel(
            c.id,
            c.label,
            description: c.description,
            importance: c == AppNotificationChannel.messages
                ? Importance.max
                : Importance.high,
          ),
        );
      }
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
    if (response.actionId == replyActionId) {
      unawaited(_handleReply(response));
      return;
    }
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
    if (PushDelivery.oneSignalActive) return;
    FirebaseMessaging.onMessage.listen((msg) async {
      await showRemoteMessage(msg);
    });
    await bindOpenedAppHandlers(messaging);
  }

  Future<void> bindOpenedAppHandlers(FirebaseMessaging messaging) async {
    if (PushDelivery.oneSignalActive) return;
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
    if (PushDelivery.oneSignalActive) return;

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

    // Kullanıcı bu kanalı kapattıysa bildirim gösterilmez (uygulama içi
    // "Bildirimler" listesi yine de sunucudan dolar).
    final channel = AppNotificationChannel.forType(type);
    if (!await const NotificationChannelPrefs().isEnabled(channel)) return;

    // Direkt mesaj: gönderen adı/avatarı/metni ile MessagingStyle + Yanıtla.
    final message = MessageNotificationData.tryParse(
      data,
      fallbackTitle: title,
      fallbackBody: body,
    );
    if (message != null) {
      await showMessageNotification(message);
      return;
    }

    final payload = data.isNotEmpty
        ? jsonEncode(data)
        : msg.data['targetPath']?.toString();

    final android = AndroidNotificationDetails(
      channel.id,
      channel.label,
      channelDescription: channel.description,
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
      payload: payload,
    );
  }

  // ── Direkt mesaj bildirimi (WhatsApp tarzı) ────────────────────────────────

  /// Kişi başına son mesajlar (Android MessagingStyle geçmişi).
  static final Map<String, List<_ChatLine>> _history = {};
  static const _historyMax = 6;
  static final Map<String, String> _avatarFileCache = {};

  /// Gönderen adı + avatar + mesaj metniyle bildirim; Android'de RemoteInput
  /// "Yanıtla", iOS'ta metin girişli kategori. Dokunma → `/chat/{senderId}`.
  Future<void> showMessageNotification(
    MessageNotificationData m, {
    bool recordIncoming = true,
  }) async {
    if (!_initialized) await init();
    if (recordIncoming) {
      _addLine(
        m.senderId,
        _ChatLine(
          text: m.text ?? 'Yeni mesaj gönderdi',
          at: DateTime.now(),
          fromMe: false,
        ),
      );
    }
    final avatarPath = await _avatarFile(m.avatarUrl);
    final sender = Person(
      name: m.senderName,
      key: m.senderId,
      important: true,
      icon: avatarPath != null ? BitmapFilePathAndroidIcon(avatarPath) : null,
    );
    const me = Person(name: 'Siz', key: 'me');
    final lines = _history[m.senderId] ?? const <_ChatLine>[];

    final style = MessagingStyleInformation(
      me,
      conversationTitle: m.senderName,
      groupConversation: false,
      messages: [
        for (final l in lines) Message(l.text, l.at, l.fromMe ? me : sender),
      ],
    );

    final android = AndroidNotificationDetails(
      AppNotificationChannel.messages.id,
      AppNotificationChannel.messages.label,
      channelDescription: AppNotificationChannel.messages.description,
      importance: Importance.max,
      priority: Priority.max,
      category: AndroidNotificationCategory.message,
      styleInformation: style,
      icon: '@mipmap/ic_launcher',
      largeIcon:
          avatarPath != null ? FilePathAndroidBitmap(avatarPath) : null,
      actions: const [
        AndroidNotificationAction(
          replyActionId,
          'Yanıtla',
          inputs: [AndroidNotificationActionInput(label: 'Mesaj yaz…')],
          allowGeneratedReplies: true,
          showsUserInterface: false,
          // Yanıtlandıktan sonra bildirim yeniden güncellenir (spinner kalmaz).
          cancelNotification: false,
        ),
      ],
    );
    final ios = DarwinNotificationDetails(
      categoryIdentifier: messageCategoryId,
      threadIdentifier: m.senderId,
    );

    await _local.show(
      m.notificationId,
      m.senderName,
      m.text ?? 'Yeni mesaj',
      NotificationDetails(android: android, iOS: ios),
      payload: jsonEncode({
        'type': 'message',
        'senderId': m.senderId,
        'senderName': m.senderName,
        if (m.avatarUrl != null) 'senderAvatar': m.avatarUrl,
        'targetPath': m.targetPath,
        'targetId': m.senderId,
      }),
    );
  }

  void _addLine(String senderId, _ChatLine line) {
    final list = _history.putIfAbsent(senderId, () => <_ChatLine>[]);
    list.add(line);
    if (list.length > _historyMax) list.removeAt(0);
  }

  Future<String?> _avatarFile(String? url) async {
    final u = url?.trim();
    if (u == null || u.isEmpty || kIsWeb) return null;
    final cached = _avatarFileCache[u];
    if (cached != null && File(cached).existsSync()) return cached;
    try {
      final uri = Uri.parse(u);
      final client = HttpClient()
        ..connectionTimeout = const Duration(seconds: 4);
      final req = await client.getUrl(uri).timeout(const Duration(seconds: 4));
      final res = await req.close().timeout(const Duration(seconds: 6));
      if (res.statusCode != 200) return null;
      final bytes = await consolidateHttpClientResponseBytes(res);
      final file = File(
        '${Directory.systemTemp.path}/notif_avatar_${u.hashCode.abs()}.img',
      );
      await file.writeAsBytes(bytes, flush: true);
      client.close();
      _avatarFileCache[u] = file.path;
      return file.path;
    } catch (_) {
      return null; // avatar yoksa harf/varsayılan simge kullanılır
    }
  }

  // ── Yanıtla (RemoteInput / UNTextInputNotificationAction) ─────────────────

  Future<void> _handleReply(NotificationResponse response) async {
    final input = response.input?.trim();
    final peer = _senderIdFromPayload(response.payload);
    if (input == null || input.isEmpty || peer == null) return;
    await _sendReplyAndAck(
      peer,
      input,
      senderName: _senderNameFromPayload(response.payload),
    );
  }

  /// Uygulama kapalıyken (arka plan isolate) aksiyon.
  static Future<void> handleBackgroundResponse(
    NotificationResponse response,
  ) async {
    if (response.actionId != replyActionId) return;
    final input = response.input?.trim();
    final peer = _senderIdFromPayload(response.payload);
    if (input == null || input.isEmpty || peer == null) return;
    final svc = PushNotificationService.instance;
    await svc.init();
    await svc._sendReplyAndAck(
      peer,
      input,
      senderName: _senderNameFromPayload(response.payload),
    );
  }

  Future<void> _sendReplyAndAck(
    String peerId,
    String text, {
    String? senderName,
  }) async {
    final name = senderName ?? 'Sohbet';
    try {
      await NotificationReplySender.send(peerId, text);
      _addLine(
        peerId,
        _ChatLine(text: text, at: DateTime.now(), fromMe: true),
      );
      // Aynı bildirimi "Siz: …" ile güncelle → Android yanıt spinner'ı kapanır.
      await showMessageNotification(
        MessageNotificationData(
          senderId: peerId,
          senderName: name,
          targetPath: '/chat/$peerId',
        ),
        recordIncoming: false,
      );
    } catch (e) {
      if (kDebugMode) debugPrint('Notification reply failed: $e');
      await _local.show(
        MessageNotificationData(
          senderId: peerId,
          senderName: name,
          targetPath: '/chat/$peerId',
        ).notificationId,
        name,
        'Yanıt gönderilemedi — dokunup uygulamada tekrar deneyin.',
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'canlifal_messages',
            'Mesajlar',
            importance: Importance.max,
            priority: Priority.max,
            icon: '@mipmap/ic_launcher',
          ),
        ),
        payload: jsonEncode({
          'type': 'message',
          'senderId': peerId,
          'targetPath': '/chat/$peerId',
        }),
      );
    }
  }

  static Map<String, dynamic>? _decode(String? payload) {
    final p = payload?.trim();
    if (p == null || !p.startsWith('{')) return null;
    try {
      final d = jsonDecode(p);
      if (d is Map) return d.map((k, v) => MapEntry(k.toString(), v));
    } catch (_) {}
    return null;
  }

  static String? _senderIdFromPayload(String? payload) {
    final d = _decode(payload);
    final id = (d?['senderId'] ?? d?['targetId'])?.toString().trim();
    return (id == null || id.isEmpty) ? null : id;
  }

  static String? _senderNameFromPayload(String? payload) {
    final n = _decode(payload)?['senderName']?.toString().trim();
    return (n == null || n.isEmpty) ? null : n;
  }

  Future<String?> currentFcmToken() async {
    if (kIsWeb) return null;
    try {
      return await FirebaseMessaging.instance.getToken();
    } catch (e) {
      if (kDebugMode) debugPrint('FCM getToken failed: $e');
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
    // Uygulama içi "Bildirimler" listesine de düşsün (acil/arama bildirimleri hariç).
    if (!urgent) {
      try {
        await LocalNotificationStore.record(
          title: title,
          body: body,
          type: 'local',
          targetPath: payload != null && payload.startsWith('/') ? payload : null,
        );
        PushNavigationHandler.onPushReceived?.call();
      } catch (_) {}
    }
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

  static const _dailyFortuneReminderId = 88001;

  /// Günlük fal hatırlatıcısı — günde bir kez.
  Future<void> setDailyFortuneReminderEnabled(bool enabled) async {
    if (kIsWeb) return;
    if (!_initialized) await init();
    if (!enabled) {
      await _local.cancel(_dailyFortuneReminderId);
      return;
    }
    final android = AndroidNotificationDetails(
      AppNotificationChannel.dailyFortune.id,
      AppNotificationChannel.dailyFortune.label,
      channelDescription: AppNotificationChannel.dailyFortune.description,
      importance: Importance.defaultImportance,
      icon: '@mipmap/ic_launcher',
    );
    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentSound: true,
    );
    final details = NotificationDetails(android: android, iOS: iosDetails);
    await _local.periodicallyShow(
      _dailyFortuneReminderId,
      'Günlük falın hazır ✨',
      'Bugünün kehanetini ve enerjini keşfet.',
      RepeatInterval.daily,
      details,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      payload: '/fortune/gunluk-fal',
    );
  }
}

class _ChatLine {
  const _ChatLine({required this.text, required this.at, required this.fromMe});

  final String text;
  final DateTime at;
  final bool fromMe;
}
