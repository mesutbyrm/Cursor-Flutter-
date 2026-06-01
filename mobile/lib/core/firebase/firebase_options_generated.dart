// Stub — `scripts/generate-firebase-options.sh` google-services.json ile üretir.

import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;

abstract final class FirebaseOptionsGenerated {
  static const bool isConfigured = false;

  static FirebaseOptions get currentPlatform {
    throw StateError(
      'FirebaseOptionsGenerated: google-services.json yok. '
      'bash scripts/sync-canlifal-config.sh veya dosyayı mobile/android/app/ altına koyun.',
    );
  }
}
