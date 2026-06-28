import 'package:canlifal_social/core/config/env.dart';

/// Uzak görsel URL'leri — thumbnail vs tam çözünürlük.
abstract final class CanlifalImageUrls {
  static const defaultThumbnailWidth = 480;
  static const avatarThumbnailWidth = 128;
  static const feedThumbnailWidth = 720;
  static const fullMaxWidth = 2048;

  /// Göreli yolları mutlak URL'ye çevirir.
  static String resolve(String? raw) {
    if (raw == null) return '';
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return '';
    if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) {
      return trimmed;
    }
    if (trimmed.startsWith('//')) return 'https:$trimmed';
    final base = Env.siteOrigin;
    return trimmed.startsWith('/') ? '$base$trimmed' : '$base/$trimmed';
  }

  /// Liste / kart / avatar — düşük bant genişliği thumbnail URL.
  static String thumbnail(
    String? raw, {
    int width = defaultThumbnailWidth,
    int quality = 80,
  }) {
    final url = resolve(raw);
    if (url.isEmpty) return url;

    final uri = Uri.tryParse(url);
    if (uri == null) return url;

    if (_isPreSizedThumb(uri)) return url;

    if (uri.host.contains('images.unsplash.com')) {
      return _withQuery(uri, {
        'auto': 'format',
        'fit': 'crop',
        'w': '$width',
        'q': '${quality.clamp(60, 95)}',
        'fm': 'webp',
      });
    }

    if (uri.host.contains('canlifal.com') && !uri.path.contains('_next/image')) {
      final encoded = Uri.encodeComponent(url);
      return '${Env.siteOrigin}/_next/image?url=$encoded&w=$width&q=$quality';
    }

    if (uri.path.contains('_next/image')) {
      return _withQuery(uri, {'w': '$width', 'q': '$quality'});
    }

    return url;
  }

  /// Detay / tam ekran — orijinal (istemci tarafında memCache sınırı uygulanır).
  static String full(String? raw) => resolve(raw);

  static bool _isPreSizedThumb(Uri uri) {
    final host = uri.host.toLowerCase();
    if (host.contains('ytimg.com')) return true;
    if (host.contains('googleusercontent.com') &&
        uri.path.contains('=s')) {
      return true;
    }
    return false;
  }

  static String _withQuery(Uri uri, Map<String, String> params) {
    return uri.replace(queryParameters: {...uri.queryParameters, ...params}).toString();
  }
}
