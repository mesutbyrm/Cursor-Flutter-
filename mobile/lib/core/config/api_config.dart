import 'env.dart';

/// Tek kaynak — backend sözleşmesi (`FLUTTER_BACKEND_ENTEGRASYON_PROMPT.md`).
///
/// Production: `https://canlifal.com` + `/api/v1` öneki.
/// Eski `/api/...` yolları geriye dönük çalışır; yeni kod [path] ile v1 üretir.
abstract final class ApiConfig {
  static String get baseUrl => Env.siteOrigin;

  /// Versiyonlu API öneki — yeni endpoint'ler için zorunlu.
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

  /// `dart-define=USE_API_V1=false` ile eski `/api/...` yollarına dön.
  static const bool useApiV1 = bool.fromEnvironment(
    'USE_API_V1',
    defaultValue: true,
  );
}
