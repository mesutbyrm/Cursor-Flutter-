import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../onesignal/onesignal_bootstrap.dart';
import 'push_delivery.dart';
import 'push_notification_service.dart';

/// Android 13+ (POST_NOTIFICATIONS) / iOS bildirim izni.
///
/// İzin girişten hemen sonra değil, kabuk açıldıktan **gecikmeli** (bkz.
/// `PushLifecycleListener`) ve Gelen Kutusu açılınca istenir. Kullanıcı
/// reddederse en fazla [maxPrompts] kez, her biri en az [minGap] arayla
/// yeniden sorulur; son denemede sistem ayarlarına yönlendirilir.
abstract final class NotificationPermissionPrompter {
  static const _promptedKey = 'notif_permission_prompted_v1';
  static const _countKey = 'notif_permission_prompt_count_v2';
  static const _lastAtKey = 'notif_permission_prompt_at_v2';

  static const int maxPrompts = 3;
  static const Duration minGap = Duration(days: 2);

  @visibleForTesting
  static bool shouldPrompt({
    required bool granted,
    required bool prompted,
    int count = 0,
    DateTime? lastAt,
    DateTime? now,
  }) {
    if (granted) return false;
    if (!prompted && count == 0) return true;
    if (count >= maxPrompts) return false;
    final last = lastAt;
    if (last == null) return true;
    return (now ?? DateTime.now()).difference(last) >= minGap;
  }

  /// İzin istendiyse true döner (sonuçtan bağımsız).
  static Future<bool> maybePrompt() async {
    if (kIsWeb) return false;
    final prefs = await SharedPreferences.getInstance();
    final prompted = prefs.getBool(_promptedKey) ?? false;
    final count = prefs.getInt(_countKey) ?? (prompted ? 1 : 0);
    final lastMs = prefs.getInt(_lastAtKey);
    final lastAt =
        lastMs == null ? null : DateTime.fromMillisecondsSinceEpoch(lastMs);

    final granted = PushDelivery.oneSignalActive
        ? OneSignalBootstrap.permissionGranted
        : await PushNotificationService.instance.refreshPermissionStatus();
    if (granted) {
      if (PushDelivery.oneSignalActive) {
        await OneSignalBootstrap.optInIfPermitted();
      }
      return false;
    }
    if (!shouldPrompt(
      granted: granted,
      prompted: prompted,
      count: count,
      lastAt: lastAt,
    )) {
      return false;
    }

    await prefs.setBool(_promptedKey, true);
    await prefs.setInt(_countKey, count + 1);
    await prefs.setInt(_lastAtKey, DateTime.now().millisecondsSinceEpoch);
    final lastAttempt = count + 1 >= maxPrompts;
    if (PushDelivery.oneSignalActive) {
      await OneSignalBootstrap.requestPermission(fallbackToSettings: lastAttempt);
    } else {
      await PushNotificationService.instance.requestSystemPermission();
    }
    return true;
  }
}
