import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';

import '../push/message_notification_data.dart';
import '../push/notification_channels.dart';
import '../push/push_navigation_handler.dart';
import '../push/push_notification_service.dart';
import 'onesignal_config.dart';
import '../../features/live_psychics/presentation/controllers/psychic_push_action_bridge.dart';

typedef OneSignalTokenRefreshCallback = void Function();

/// OneSignal push SDK — Firebase FCM ile birlikte (Android teslimat kanalı).
class OneSignalBootstrap {
  OneSignalBootstrap._();

  static bool _ready = false;
  static String? _externalUserId;
  /// SDK hazır olmadan istenen giriş eşlemesi — init bitince yeniden denenir.
  /// (Başlatma, ilk karenin ardından gecikmeli yapıldığından `login` çoğu zaman
  /// SDK'dan önce çağrılıyordu ve kullanıcı external_id'siz kalıyordu; sunucu
  /// bildirimleri `external_id` ile hedeflediği için hiç bildirim gelmiyordu.)
  static String? _pendingExternalUserId;
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
          if (kDebugMode) {
            debugPrint('OneSignal push token: ${token.substring(0, 12)}…');
          }
          onPushTokenChanged?.call();
        }
      });

      OneSignal.Notifications.addClickListener((event) {
        final actionId = event.result.actionId;
        final data = event.notification.additionalData;
        final map = data == null
            ? <String, dynamic>{}
            : Map<String, dynamic>.from(
                data.map((k, v) => MapEntry(k.toString(), v)),
              );
        unawaited(() async {
          final handled = await PsychicPushActionBridge.handle(
            actionId: actionId,
            data: map.isEmpty ? null : map,
          );
          if (!handled) {
            PushNavigationHandler.handleNotificationTap(map.isEmpty ? null : map);
          }
        }());
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
        if (isFortuneInvite) return;
        unawaited(() async {
          // Kullanıcı kanalı kapattıysa gösterme (uygulama içi liste yine dolar).
          final channel = AppNotificationChannel.forType(
            data['type']?.toString(),
          );
          final enabled = await const NotificationChannelPrefs().isEnabled(
            channel,
          );
          if (enabled) {
            // Direkt mesaj: gönderen adı/avatarı/metni + "Yanıtla" ile göster.
            final message = MessageNotificationData.tryParse(
              data,
              fallbackTitle: event.notification.title,
              fallbackBody: event.notification.body,
            );
            if (message != null) {
              await PushNotificationService.instance.showMessageNotification(
                message,
              );
            } else {
              event.notification.display();
            }
          }
          PushNavigationHandler.onPushReceived?.call();
        }());
      });

      _ready = true;
      debugPrint('OneSignal: initialized');
      final pending = _pendingExternalUserId;
      if (pending != null && pending.isNotEmpty) {
        await login(pending);
      }
      await optInIfPermitted();
    } catch (e, st) {
      debugPrint('OneSignal init failed: $e\n$st');
    }
  }

  /// Oturum açıldığında kullanıcıyı OneSignal’de eşle (external_id).
  static Future<void> login(String externalUserId) async {
    if (externalUserId.isEmpty) return;
    if (!_ready) {
      _pendingExternalUserId = externalUserId;
      return;
    }
    if (_externalUserId == externalUserId) return;
    try {
      await OneSignal.login(externalUserId);
      _externalUserId = externalUserId;
      _pendingExternalUserId = null;
      debugPrint('OneSignal login: $externalUserId');
    } catch (e) {
      debugPrint('OneSignal login failed: $e');
    }
  }

  static Future<void> logout() async {
    _pendingExternalUserId = null;
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

  /// OneSignal abonelik kimliği (tanılama).
  static String? get subscriptionId {
    if (!_ready) return null;
    final id = OneSignal.User.pushSubscription.id;
    return (id == null || id.isEmpty) ? null : id;
  }

  /// Push aboneliği açık mı (izin + opt-in).
  static bool get optedIn {
    if (!_ready) return false;
    return OneSignal.User.pushSubscription.optedIn ?? false;
  }

  /// İzin verilmiş ama abonelik kapalıysa (ör. önceki reddetme) yeniden açar.
  static Future<void> optInIfPermitted() async {
    if (!_ready || kIsWeb) return;
    try {
      if (OneSignal.Notifications.permission && !optedIn) {
        await OneSignal.User.pushSubscription.optIn();
      }
    } catch (e) {
      debugPrint('OneSignal optIn failed: $e');
    }
  }

  static bool get permissionGranted {
    if (!_ready) return false;
    return OneSignal.Notifications.permission;
  }

  static Future<bool> requestPermission({bool fallbackToSettings = false}) async {
    if (!_ready || kIsWeb) return false;
    try {
      final ok = await OneSignal.Notifications.requestPermission(
        fallbackToSettings,
      );
      if (ok) await optInIfPermitted();
      return ok;
    } catch (e) {
      debugPrint('OneSignal requestPermission failed: $e');
      return false;
    }
  }
}
