/// API tabanı. Derleme sırasında:
/// `flutter run --dart-define=API_BASE_URL=https://api.example.com`
class Env {
  Env._();

  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://canlifal.com',
  );

  /// canlifal.com üretim sitesi NextAuth (çerez) + `/api/*` JSON uçları kullanır.
  static bool get useNextAuth {
    final u = apiBaseUrl.toLowerCase();
    return u.contains('canlifal.com') && !u.contains('.local');
  }

  static String get siteOrigin {
    var u = apiBaseUrl.trim();
    if (u.endsWith('/')) u = u.substring(0, u.length - 1);
    return u;
  }
}
