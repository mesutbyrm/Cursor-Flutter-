import '../firebase/firebase_options_generated.dart';
import 'env.dart';

/// Google Sign-In — Web OAuth client ID (idToken için zorunlu).
abstract final class GoogleAuthConfig {
  GoogleAuthConfig._();

  /// Sıra: `--dart-define=GOOGLE_SERVER_CLIENT_ID` → [FirebaseOptionsGenerated.googleWebClientId].
  static String? get serverClientId {
    final fromDefine = Env.googleServerClientId.trim();
    if (fromDefine.isNotEmpty) return fromDefine;
    final fromFirebase = FirebaseOptionsGenerated.googleWebClientId.trim();
    if (fromFirebase.isNotEmpty) return fromFirebase;
    return null;
  }

  static bool get isConfigured => serverClientId != null;

  static String get setupHint => '''
Google ile giriş için şunlar gerekli:

1) Firebase Console → Proje → Android uygulaması (com.mesutbyrm.canlifal)
2) google-services.json dosyasını mobile/android/app/ altına koyun
3) Google Cloud → OAuth 2.0 → Web client ID (serverClientId)
4) Android OAuth istemcisine SHA-1 parmak izi ekleyin (debug + release)

APK derlerken:
  GOOGLE_SERVER_CLIENT_ID=xxx.apps.googleusercontent.com

veya google-services.json içinde Web client (client_type: 3) tanımlı olsun.

SHA-1 almak için:
  cd mobile/android && ./gradlew signingReport
''';
}
