import 'dart:async';

import 'package:flutter/foundation.dart';

/// Giriş sonrası TRTC — yalnızca işaret; izin/SDK sesli odaya girerken açılır.
///
/// Girişten hemen sonra mikrofon/kamera izni istemek Android'de activity
/// yeniden başlatıp oturumu düşürüyordu.
abstract final class TrtcBootstrapService {
  static var _initialized = false;

  static Future<void> prewarmAfterAuth() async {
    if (kIsWeb || _initialized) return;
    _initialized = true;
  }

  @visibleForTesting
  static void resetForTest() => _initialized = false;
}
