import 'package:canlifal_social/core/config/env.dart';
import 'package:canlifal_social/core/media/cloud_media_url.dart';

/// Uzak görsel URL'leri — thumbnail vs tam çözünürlük.
abstract final class CanlifalImageUrls {
  static const defaultThumbnailWidth = 480;
  static const avatarThumbnailWidth = 128;
  static const feedThumbnailWidth = 720;
  static const fullMaxWidth = 2048;

  /// Göreli yolları mutlak URL'ye çevirir (R2 `shorts/*` → CDN).
  static String resolve(String? raw) {
    if (raw == null) return '';
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return '';
    if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) {
      return trimmed;
    }
    if (trimmed.startsWith('//')) return 'https:$trimmed';
    final cloud = CloudMediaUrl.resolve(trimmed);
    if (cloud != null && cloud.startsWith('http')) return cloud;
    // Hediye / sticker / emoji paketleri — CDN öncelikli.
    if (_isCdnRelativePath(trimmed)) {
      final cdn = CloudMediaUrl.resolve(trimmed);
      if (cdn != null) return cdn;
    }
    final base = Env.siteOrigin;
    return trimmed.startsWith('/') ? '$base$trimmed' : '$base/$trimmed';
  }

  static bool _isCdnRelativePath(String path) {
    final lower = path.toLowerCase();
    const prefixes = [
      'gift/',
      'gifts/',
      'stickers/',
      'emoji/',
      'shorts/',
      'stories/',
      'reels/',
      'avatars/',
      'banners/',
      'effects/',
      'splash/',
    ];
    for (final p in prefixes) {
      if (lower.startsWith(p)) return true;
    }
    return false;
  }

  /// Video yolundan küçük resim URL'si türet (`shorts/videos/x.mp4` → `shorts/thumbs/x.jpg`).
  static String? thumbFromVideoUrl(String? videoUrl) {
    final resolved = resolve(videoUrl);
    if (resolved.isEmpty) return null;
    final lower = resolved.toLowerCase();
    if (!lower.contains('shorts/')) return null;
    var thumb = resolved
        .replaceAll('/shorts/videos/', '/shorts/thumbs/')
        .replaceAll(RegExp(r'\.(mp4|webm|mov|m4v)$', caseSensitive: false), '.jpg');
    if (thumb == resolved) {
      thumb = '$resolved.jpg';
    }
    return thumb;
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

    // canlifal.com'un /_next/image optimizasyon uç noktası bu ortamda 404
    // dönüyor (her genişlik/relatif-mutlak varyasyonu doğrulandı) → görseller
    // hiç yüklenmiyordu (ör. hazır oda arka planlarının çoğu boş kalıyordu).
    // Statik /images/... doğrudan 200 döndüğü için orijinal URL kullanılır.
    // Zaten _next/image içeren URL'lerde de yalnızca boyut parametreleri
    // güncellenmez; bozuk uç noktaya dokunulmaz.
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
