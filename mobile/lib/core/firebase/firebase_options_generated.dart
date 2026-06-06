// Stub — `scripts/generate-firebase-options.sh` google-services.json ile üretir.

import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;

abstract final class FirebaseOptionsGenerated {
  static const bool isConfigured = false;

  /// OAuth Web client (google-services.json client_type: 3) — Google Sign-In idToken.
  static const String googleWebClientId = '';

  static FirebaseOptions get currentPlatform {
    throw StateError(
      'FirebaseOptionsGenerated: google-services.json yok. '
      'bash scripts/sync-canlifal-config.sh veya dosyayı mobile/android/app/ altına koyun.',
    );
  }
}
