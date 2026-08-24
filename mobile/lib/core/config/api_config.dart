import 'env.dart';

/// Tek kaynak — backend sözleşmesi (`FLUTTER_BACKEND_ENTEGRASYON_PROMPT.md`).
///
/// Production: `https://canlifal.com` + `/api` öneki.
/// `/api/v1` yalnızca özel/self-hosted backend açıkça istendiğinde kullanılır.
abstract final class ApiConfig {
  static String get baseUrl => Env.siteOrigin;

  /// Opsiyonel versiyonlu API öneki.
  static const String apiPrefix = '/api/v1';

  /// Eski (geriye dönük) önek.
  static const String legacyApiPrefix = '/api';

  /// Tam URL: `https://canlifal.com/api/v1/auth/mobile-login`
  static String url(String relativePath) {
    final p = relativePath.startsWith('/') ? relativePath : '/$relativePath';
    return '$baseUrl$apiPrefix$p';
  }

  /// Dio [BaseOptions.baseUrl] — path'ler `/auth/...` ile başlar.
  static String get dioBaseUrl => '$baseUrl$apiPrefix';

  /// [Env.apiBaseUrl] ile uyumlu tam path tabanı (mevcut `ApiEndpoints` stili).
  static String get legacyDioBaseUrl => baseUrl;

  /// Kılavuzdaki production contract `/api/...` olduğu için varsayılan kapalı.
  /// Self-hosted `/api/v1` mirror gerekiyorsa `dart-define=USE_API_V1=true`.
  static const bool useApiV1 = bool.fromEnvironment(
    'USE_API_V1',
    defaultValue: false,
  );
}
