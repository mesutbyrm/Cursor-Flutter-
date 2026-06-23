import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';

/// Mobil oturum kaydı için cihaz başlıkları (`x-device-*`).
Map<String, String> deviceRequestHeaders() {
  if (kIsWeb) return const {};
  try {
    final os = Platform.operatingSystem;
    final version = Platform.operatingSystemVersion;
    return {
      'x-device-platform': os,
      'x-device-label': '$os $version',
    };
  } catch (_) {
    return const {};
  }
}
