import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Mikrofon ve kamera izinlerini uygulamanın ilk açılışında bir kez ister.
/// Sonraki oda/yayın girişlerinde yalnızca yayın gönderilecekse ve izin hâlâ
/// verilmemişse sorulur (`TrtcRoomManager.requestPermissions`).
abstract final class MediaPermissionBootstrap {
  static const _prefsKey = 'media_permissions_asked_v1';
  static bool _running = false;

  static Future<void> askOnce() async {
    if (kIsWeb || _running) return;
    _running = true;
    try {
      final prefs = await SharedPreferences.getInstance();
      if (prefs.getBool(_prefsKey) == true) return;
      await prefs.setBool(_prefsKey, true);
      await [Permission.microphone, Permission.camera].request();
    } on MissingPluginException {
      // Test/masaüstü — izin eklentisi yok.
    } catch (e) {
      if (kDebugMode) debugPrint('MediaPermissionBootstrap: $e');
    } finally {
      _running = false;
    }
  }
}
