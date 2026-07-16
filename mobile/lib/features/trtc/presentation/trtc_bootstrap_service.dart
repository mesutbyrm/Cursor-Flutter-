import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:tencent_rtc_sdk/trtc_cloud.dart';

import '../data/datasources/trtc_remote_datasource.dart';
import '../data/trtc_session_store.dart';
import '../presentation/trtc_room_manager.dart';

/// Giriş sonrası TRTC motoru ısıtma — izin ve ağ kontrolü.
abstract final class TrtcBootstrapService {
  static var _initialized = false;

  static Future<void> prewarmAfterAuth() async {
    if (kIsWeb || _initialized) return;
    _initialized = true;
    try {
      final results = await Connectivity().checkConnectivity();
      if (results.every((r) => r == ConnectivityResult.none)) {
        return;
      }
      unawaited(TrtcRoomManager.requestPermissions(video: false));
      await TRTCCloud.sharedInstance();
    } catch (_) {
      _initialized = false;
    }
  }

  @visibleForTesting
  static void resetForTest() => _initialized = false;
}
