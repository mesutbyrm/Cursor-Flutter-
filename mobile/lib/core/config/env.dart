/// API tabanı. Derleme sırasında:
/// `flutter run --dart-define=API_BASE_URL=https://api.example.com`
class Env {
  Env._();

  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://api.canlifal.local',
  );
}
