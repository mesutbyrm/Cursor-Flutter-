import '../config/env.dart';

/// R2 `cloud_storage_path` → oynatılabilir CDN URL.
///
/// Üretim: `gift/gifts/uuid.mp4` → `https://cdn.girlive.com/gift/gifts/uuid.mp4`
/// Derleme: `--dart-define=CDN_MEDIA_BASE_URL=https://cdn.example.com`
abstract final class CloudMediaUrl {
  static const String cdnBase = String.fromEnvironment(
    'CDN_MEDIA_BASE_URL',
    defaultValue: 'https://cdn.girlive.com',
  );

  /// R2 anahtarı — `http` veya site kökü `/` ile başlamaz.
  static bool isCloudStoragePath(String value) {
    final v = value.trim();
    if (v.isEmpty || v.startsWith('http') || v.startsWith('/')) return false;
    return v.contains('/');
  }

  static bool isResolvable(String value) {
    final v = value.trim();
    if (v.isEmpty) return false;
    return v.startsWith('http') ||
        v.startsWith('/') ||
        isCloudStoragePath(v);
  }

  static String? resolve(String? raw, {String? siteOrigin}) {
    final trimmed = raw?.trim();
    if (trimmed == null || trimmed.isEmpty) return null;
    if (trimmed.startsWith('http')) return trimmed;

    if (isCloudStoragePath(trimmed)) {
      final base = cdnBase.trim().replaceAll(RegExp(r'/+$'), '');
      if (base.isNotEmpty) return '$base/$trimmed';
    }

    final origin =
        (siteOrigin ?? Env.webOrigin).trim().replaceAll(RegExp(r'/+$'), '');
    if (origin.isEmpty) return trimmed;
    return trimmed.startsWith('/') ? '$origin$trimmed' : '$origin/$trimmed';
  }
}
