import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

import 'firebase_options_generated.dart';

/// Firebase yapılandırması — dart-define, `google-services.json` veya ikisi.
///
/// CI / yerel (yapılandırma yok): `enabled == false` → init atlanır.
abstract final class DefaultFirebaseOptions {
  static const String _projectId = String.fromEnvironment('FIREBASE_PROJECT_ID');
  static const String _apiKey = String.fromEnvironment('FIREBASE_API_KEY');
  static const String _appId = String.fromEnvironment('FIREBASE_APP_ID');
  static const String _messagingSenderId =
      String.fromEnvironment('FIREBASE_MESSAGING_SENDER_ID');

  static bool get _fromDartDefine =>
      _projectId.isNotEmpty && _apiKey.isNotEmpty && _appId.isNotEmpty;

  static bool get enabled =>
      _fromDartDefine || FirebaseOptionsGenerated.isConfigured;

  static FirebaseOptions get currentPlatform {
    if (!enabled) {
      throw StateError(
        'Firebase not configured. google-services.json + generate script, '
        'veya --dart-define=FIREBASE_PROJECT_ID=... FIREBASE_API_KEY=... FIREBASE_APP_ID=...',
      );
    }
    if (!_fromDartDefine && FirebaseOptionsGenerated.isConfigured) {
      return FirebaseOptionsGenerated.currentPlatform;
    }
    if (kIsWeb) {
      return FirebaseOptions(
        apiKey: _apiKey,
        appId: _appId,
        messagingSenderId: _messagingSenderId,
        projectId: _projectId,
      );
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return FirebaseOptions(
          apiKey: _apiKey,
          appId: _appId,
          messagingSenderId: _messagingSenderId,
          projectId: _projectId,
        );
      case TargetPlatform.iOS:
      case TargetPlatform.macOS:
        return FirebaseOptions(
          apiKey: _apiKey,
          appId: _appId,
          messagingSenderId: _messagingSenderId,
          projectId: _projectId,
          iosBundleId: const String.fromEnvironment(
            'FIREBASE_IOS_BUNDLE_ID',
            defaultValue: 'com.mesutbyrm.canlifal',
          ),
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }
}
