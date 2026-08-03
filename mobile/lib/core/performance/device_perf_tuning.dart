import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';
import 'package:flutter/painting.dart';
import 'package:flutter/scheduler.dart';

/// Cihaz sınıfına göre bellek ve önbellek ayarları.
abstract final class DevicePerfTuning {
  static var _applied = false;

  /// Soğuk açılışta bir kez çağrılır — düşük RAM'de image cache küçültülür.
  static void apply() {
    if (_applied || kIsWeb) return;
    _applied = true;

    final lowRam = _isLowRamDevice();
    final cache = PaintingBinding.instance.imageCache;
    if (lowRam) {
      cache.maximumSize = 80;
      cache.maximumSizeBytes = 48 << 20;
    } else {
      cache.maximumSize = 200;
      cache.maximumSizeBytes = 100 << 20;
    }
  }

  static bool _isLowRamDevice() {
    if (kIsWeb) return false;
    try {
      if (Platform.isAndroid) {
        return Platform.numberOfProcessors <= 4;
      }
    } catch (_) {}
    return false;
  }

  static bool get prefersReducedMotion {
    return SchedulerBinding
            .instance.platformDispatcher.accessibilityFeatures
            .disableAnimations ||
        _isLowRamDevice();
  }
}
