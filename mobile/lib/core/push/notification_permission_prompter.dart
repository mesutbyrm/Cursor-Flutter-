import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../onesignal/onesignal_bootstrap.dart';
import 'push_notification_service.dart';

/// Android 13+ (POST_NOTIFICATIONS) / iOS bildirim izni — kullanıcı gelen kutusunu
/// açtığında BİR KEZ istenir (girişten hemen sonra değil: activity yeniden
/// başlaması/giriş ekranına dönüş sorunu yaşanmıştı). Reddedilirse izin
/// banner'ı ve Ayarlar'daki "Bildirim ayarları" yolu açık kalır.
abstract final class NotificationPermissionPrompter {
  static const _promptedKey = 'notif_permission_prompted_v1';

  @visibleForTesting
  static bool shouldPrompt({required bool granted, required bool prompted}) =>
      !granted && !prompted;

  /// İzin istendiyse true döner (sonuçtan bağımsız).
  static Future<bool> maybePrompt() async {
    if (kIsWeb) return false;
    final prefs = await SharedPreferences.getInstance();
    final prompted = prefs.getBool(_promptedKey) ?? false;

    final granted = OneSignalBootstrap.isReady
        ? OneSignalBootstrap.permissionGranted
        : await PushNotificationService.instance.refreshPermissionStatus();
    if (!shouldPrompt(granted: granted, prompted: prompted)) return false;

    await prefs.setBool(_promptedKey, true);
    if (OneSignalBootstrap.isReady) {
      await OneSignalBootstrap.requestPermission();
    } else {
      await PushNotificationService.instance.requestSystemPermission();
    }
    return true;
  }
}
