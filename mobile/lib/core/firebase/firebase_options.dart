import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Firebase yapılandırması — `flutterfire configure` veya dart-define ile doldurulur.
///
/// CI / yerel geliştirme (dosya yok): `enabled == false` → init atlanır.
/// Üretim: `flutter run --dart-define=FIREBASE_PROJECT_ID=your-project-id` ve gerçek anahtarlar.
abstract final class DefaultFirebaseOptions {
  static const String _projectId = String.fromEnvironment('FIREBASE_PROJECT_ID');
  static const String _apiKey = String.fromEnvironment('FIREBASE_API_KEY');
  static const String _appId = String.fromEnvironment('FIREBASE_APP_ID');
  static const String _messagingSenderId =
      String.fromEnvironment('FIREBASE_MESSAGING_SENDER_ID');

  static bool get enabled =>
      _projectId.isNotEmpty && _apiKey.isNotEmpty && _appId.isNotEmpty;

  static FirebaseOptions get currentPlatform {
    if (!enabled) {
      throw StateError(
        'Firebase not configured. Set FIREBASE_PROJECT_ID, FIREBASE_API_KEY, '
        'FIREBASE_APP_ID (and optional FIREBASE_MESSAGING_SENDER_ID) via --dart-define.',
      );
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
            defaultValue: 'com.canlifal.canlifalSocial',
          ),
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }
}
