import 'package:dio/dio.dart';

import '../../../core/config/env.dart';

/// YouTube watch URL → doğrudan ses akışı (site API → Piped → Invidious).
/// googlevideo URL'leri mobilde API proxy üzerinden oynatılır (Referer gerekir).
class YoutubeStreamResolver {
  YoutubeStreamResolver(this._dio);

  final Dio _dio;

  static final _youtubeHost = RegExp(r'youtube\.com|youtu\.be', caseSensitive: false);

  static const _cacheTtl = Duration(hours: 2);

  static const _pipedHosts = [
    'https://pipedapi.kavin.rocks',
    'https://pipedapi.adminforge.de',
  ];

  static const _invidiousHosts = [
    'https://invidious.privacyredirect.com',
    'https://invidious.fdn.fr',
  ];

  final Map<String, _StreamCacheEntry> _cache = {};

  bool needsResolve(String url) {
    if (isDirectPlayableUrl(url)) return false;
    return _youtubeHost.hasMatch(url);
  }

  static bool isDirectPlayableUrl(String url) {
    final u = url.trim().toLowerCase();
    if (u.isEmpty || !u.startsWith('http')) return false;
    if (_youtubeHost.hasMatch(u)) return false;
    return u.contains('googlevideo.com') ||
        u.contains('.m3u8') ||
        u.contains('mime=audio') ||
        u.endsWith('.mp3') ||
        u.endsWith('.m4a') ||
        u.endsWith('.aac') ||
        u.endsWith('.ogg') ||
        u.endsWith('.opus');
  }

  void invalidate(String musicUrl) {
    final id = videoIdFrom(musicUrl);
    if (id != null) _cache.remove(id);
  }

  String? videoIdFrom(String url) {
    final trimmed = url.trim();
    if (trimmed.length <= 15 && !trimmed.contains('/')) return trimmed;
    try {
      final u = Uri.parse(trimmed);
      if (u.host.contains('youtu.be')) {
        return u.pathSegments.isNotEmpty ? u.pathSegments.first : null;
      }
      return u.queryParameters['v'];
    } catch (_) {
      final m = RegExp(r'(?:v=|youtu\.be/)([a-zA-Z0-9_-]{6,})').firstMatch(trimmed);
      return m?.group(1);
    }
  }

  Future<String?> prefetch(String musicUrl) => resolvePlayableUrl(musicUrl);

  /// googlevideo CDN — audioplayers Referer gönderemez; API proxy kullan.
  static String wrapForMobilePlayback(String url) {
    final trimmed = url.trim();
    if (trimmed.isEmpty || !trimmed.startsWith('http')) return trimmed;
    final lower = trimmed.toLowerCase();
    if (lower.contains('/api/chat/youtube-audio')) return trimmed;
    if (!lower.contains('googlevideo.com') &&
        !lower.contains('youtube.com/api/')) {
      return trimmed;
    }
    var base = Env.apiBaseUrl.trim();
    if (base.endsWith('/')) base = base.substring(0, base.length - 1);
    return '$base/api/chat/youtube-audio?url=${Uri.encodeComponent(trimmed)}';
  }

  Future<String?> resolvePlayableUrl(String musicUrl) async {
    if (musicUrl.isEmpty) return null;
    if (isDirectPlayableUrl(musicUrl)) {
      return wrapForMobilePlayback(musicUrl);
    }
    if (!_youtubeHost.hasMatch(musicUrl)) return musicUrl;

    final id = videoIdFrom(musicUrl);
    if (id != null && id.isNotEmpty) {
      final cached = _cache[id];
      if (cached != null &&
          DateTime.now().difference(cached.at) < _cacheTtl) {
        return cached.url;
      }
    }

    final fromApi = await _resolveViaSiteApi(musicUrl);
    if (fromApi != null) {
      final wrapped = wrapForMobilePlayback(fromApi);
      _remember(id, wrapped);
      return wrapped;
    }

    if (id == null || id.isEmpty) return null;

    for (final host in _pipedHosts) {
      final piped = await _resolveViaPiped(host, id);
      if (piped != null) {
        final wrapped = wrapForMobilePlayback(piped);
        _remember(id, wrapped);
        return wrapped;
      }
    }

    for (final host in _invidiousHosts) {
      final inv = await _resolveViaInvidious(host, id);
      if (inv != null) {
        final wrapped = wrapForMobilePlayback(inv);
        _remember(id, wrapped);
        return wrapped;
      }
    }

    return null;
  }

  void _remember(String? id, String url) {
    if (id == null || id.isEmpty || !url.startsWith('http')) return;
    _cache[id] = _StreamCacheEntry(url: url, at: DateTime.now());
  }

  Future<String?> _resolveViaSiteApi(String musicUrl) async {
    try {
      final res = await _dio.get<dynamic>(
        '/api/chat/youtube-stream',
        queryParameters: {'url': musicUrl},
        options: Options(receiveTimeout: const Duration(seconds: 8)),
      );
      final data = res.data;
      if (data is Map) {
        final stream = data['streamUrl'] ?? data['url'];
        if (stream is String && stream.startsWith('http')) return stream;
      }
    } catch (_) {}
    return null;
  }

  Future<String?> _resolveViaPiped(String host, String id) async {
    try {
      final res = await _dio.get<dynamic>(
        '$host/streams/$id',
        options: Options(
          headers: {'Accept': 'application/json'},
          receiveTimeout: const Duration(seconds: 5),
        ),
      );
      final data = res.data;
      if (data is! Map) return null;
      final streams = <Map<String, dynamic>>[];
      for (final key in ['audioStreams', 'audioOnly']) {
        final raw = data[key];
        if (raw is List) {
          for (final e in raw) {
            if (e is Map) streams.add(Map<String, dynamic>.from(e));
          }
        }
      }
      if (streams.isEmpty) return null;
      streams.sort(
        (a, b) => ((b['bitrate'] as num?) ?? 0).compareTo((a['bitrate'] as num?) ?? 0),
      );
      final url = streams.first['url']?.toString();
      if (url != null && url.startsWith('http')) return url;
    } catch (_) {}
    return null;
  }

  Future<String?> _resolveViaInvidious(String host, String id) async {
    try {
      final res = await _dio.get<dynamic>(
        '$host/api/v1/videos/$id',
        options: Options(
          headers: {'Accept': 'application/json'},
          receiveTimeout: const Duration(seconds: 5),
        ),
      );
      final data = res.data;
      if (data is! Map) return null;
      final adaptive = data['adaptiveFormats'];
      if (adaptive is! List) return null;
      String? best;
      var bestBitrate = -1;
      for (final raw in adaptive) {
        if (raw is! Map) continue;
        final type = raw['type']?.toString() ?? '';
        if (!type.startsWith('audio/')) continue;
        final url = raw['url']?.toString();
        final bitrate = raw['bitrate'] as num? ?? 0;
        if (url != null && url.startsWith('http') && bitrate > bestBitrate) {
          bestBitrate = bitrate.toInt();
          best = url;
        }
      }
      return best;
    } catch (_) {}
    return null;
  }
}

class _StreamCacheEntry {
  const _StreamCacheEntry({required this.url, required this.at});

  final String url;
  final DateTime at;
}
