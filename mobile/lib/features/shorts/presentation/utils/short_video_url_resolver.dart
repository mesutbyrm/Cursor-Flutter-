import 'package:dio/dio.dart';

import '../../../../core/config/env.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../../../core/util/json_util.dart';

/// Kısa video CDN URL'lerini oynatılabilir aday listesine çevirir.
///
/// Üretimde `cdn.canlifal.com` bazen 404 döndüğünde sırayla:
/// 1. Orijinal URL
/// 2. `POST /api/upload/get-url` ile imzalı R2 URL (oturumlu)
/// 3. `GET /api/short-videos/:id/stream` (API proxy)
class ShortVideoUrlResolver {
  ShortVideoUrlResolver(this._dio);

  final Dio _dio;

  /// R2 anahtarı: `shorts/videos/{uuid}.mp4`
  static String? storageKeyFromUrl(String url) {
    final trimmed = url.trim();
    if (trimmed.isEmpty) return null;
    final uri = Uri.tryParse(trimmed);
    if (uri == null) return null;
    final path = uri.path.startsWith('/') ? uri.path.substring(1) : uri.path;
    if (path.startsWith('shorts/')) return path;
    final idx = path.indexOf('shorts/');
    if (idx >= 0) return path.substring(idx);
    return null;
  }

  Future<List<String>> resolvePlayUrls({
    required String videoUrl,
    String? videoId,
  }) async {
    final seen = <String>{};
    final out = <String>[];

    void add(String? raw) {
      final u = raw?.trim();
      if (u == null || u.isEmpty || !seen.add(u)) return;
      out.add(u);
    }

    add(videoUrl);

    final key = storageKeyFromUrl(videoUrl);
    if (key != null) {
      add(await _fetchSignedUrl(key, isPublic: true));
      add(await _fetchSignedUrl(key, isPublic: false));
    }

    if (videoId != null && videoId.trim().isNotEmpty) {
      add('${Env.siteOrigin}${ApiEndpoints.shortVideoStream(videoId.trim())}');
    }

    return out;
  }

  Future<String?> _fetchSignedUrl(String cloudPath, {required bool isPublic}) async {
    try {
      final res = await _dio.post<dynamic>(
        ApiEndpoints.uploadGetUrl,
        data: {
          'cloud_storage_path': cloudPath,
          'isPublic': isPublic,
        },
      );
      final body = res.data;
      if (body is! Map) return null;
      final m = Map<String, dynamic>.from(body);
      if (m['success'] == true && m['data'] is Map) {
        m.addAll(Map<String, dynamic>.from(m['data'] as Map));
      }
      return pick(m, ['url', 'signedUrl', 'downloadUrl'])?.toString();
    } catch (_) {
      return null;
    }
  }
}
