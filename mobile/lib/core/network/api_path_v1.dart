import '../config/api_config.dart';

/// `/api/...` → `/api/v1/...` dönüşümü (geriye dönük uyum).
abstract final class ApiPathV1 {
  /// Mevcut [ApiEndpoints] sabitlerini v1'e çevirir.
  ///
  /// `/api/auth/mobile-login` → `/api/v1/auth/mobile-login`
  /// `/api/v1/me` → değişmez
  static String fromLegacy(String path) {
    final trimmed = path.trim();
    if (!ApiConfig.useApiV1) return trimmed;
    if (trimmed.startsWith('/api/v1/')) return trimmed;
    if (trimmed.startsWith('/api/')) {
      return trimmed.replaceFirst('/api/', '/api/v1/');
    }
    if (trimmed.startsWith('api/')) {
      return '/api/v1/${trimmed.substring(4)}';
    }
    return trimmed.startsWith('/') ? '/api/v1$trimmed' : '/api/v1/$trimmed';
  }

  /// Göreli path (`/auth/mobile-login`) → tam v1 path.
  static String relative(String relativePath) {
    final p = relativePath.startsWith('/') ? relativePath : '/$relativePath';
    return '${ApiConfig.apiPrefix}$p';
  }
}
