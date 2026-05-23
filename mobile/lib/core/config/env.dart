import 'package:flutter/foundation.dart' show kIsWeb;

/// API tabanı. Derleme sırasında:
/// `flutter run --dart-define=API_BASE_URL=https://api.example.com`
class Env {
  Env._();

  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://canlifal.com',
  );

  /// canlifal.com üretim sitesi NextAuth (çerez) + `/api/*` JSON uçları kullanır.
  /// E-posta/Google girişi SQL JWT değil NextAuth credentials / signin/google ile yapılır.
  static bool get useNextAuth {
    final u = apiBaseUrl.toLowerCase();
    return u.contains('canlifal.com') && !u.contains('.local');
  }

  static String get siteOrigin {
    var u = apiBaseUrl.trim();
    if (u.endsWith('/')) u = u.substring(0, u.length - 1);
    return u;
  }

  /// Google Sign-In server client ID (OAuth 2.0 Web client).
  static const String googleServerClientId = String.fromEnvironment(
    'GOOGLE_SERVER_CLIENT_ID',
    defaultValue: '',
  );

  static const String tiktokClientKey = String.fromEnvironment(
    'TIKTOK_CLIENT_KEY',
    defaultValue: '',
  );

  static const String tiktokRedirectUri = String.fromEnvironment(
    'TIKTOK_REDIRECT_URI',
    defaultValue: 'canlifal://tiktok-auth',
  );

  static bool get hasTikTokLogin =>
      tiktokClientKey.trim().isNotEmpty && !kIsWeb;
}
