import 'package:dio/dio.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';

/// YouTube watch URL → doğrudan ses akışı (site API → Piped → Invidious).
/// googlevideo URL'leri mobilde API proxy veya stream loader ile oynatılır.
class YoutubeStreamResolver {
  YoutubeStreamResolver(this._dio);

  final Dio _dio;
  final YoutubeExplode _youtube = YoutubeExplode();

  static final _youtubeHost = RegExp(r'youtube\.com|youtu\.be', caseSensitive: false);

  static const _cacheTtl = Duration(hours: 2);

  static const _pipedHosts = [
    'https://pipedapi.kavin.rocks',
    'https://pipedapi.adminforge.de',
    'https://pipedapi.syncpundit.io',
    'https://pipedapi.leptons.xyz',
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
    if (u.contains('googlevideo.com') || u.contains('youtube.com/api/')) {
      return true;
    }
    return u.contains('.m3u8') ||
        u.contains('mime=audio') ||
        u.endsWith('.mp3') ||
        u.endsWith('.m4a') ||
        u.endsWith('.aac') ||
        u.endsWith('.ogg') ||
        u.endsWith('.opus');
  }

  /// googlevideo → yerel indirme (VoiceRoomDjStreamLoader). Proxy yalnızca deploy edilmişse.
  static String wrapForMobilePlayback(String url) {
    final trimmed = url.trim();
    if (trimmed.isEmpty || !trimmed.startsWith('http')) return trimmed;
    final lower = trimmed.toLowerCase();
    if (lower.contains('/api/chat/youtube-audio')) return trimmed;
    if (!lower.contains('googlevideo.com') &&
        !lower.contains('youtube.com/api/')) {
      return trimmed;
    }
    // Üretimde /api/chat/youtube-audio sık 404 — önce doğrudan CDN + stream loader
    return trimmed;
  }

  static bool isYoutubePageUrl(String url) {
    final u = url.trim().toLowerCase();
    if (u.isEmpty) return false;
    if (!u.contains('youtube.com') && !u.contains('youtu.be')) return false;
    if (u.contains('googlevideo.com')) return false;
    return u.contains('watch?v=') ||
        u.contains('youtu.be/') ||
        u.contains('/shorts/') ||
        RegExp(r'youtube\.com/v/').hasMatch(u);
  }

  static bool isDirectAudioStreamUrl(String url) {
    if (isYoutubePageUrl(url)) return false;
    return isDirectPlayableUrl(url);
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

  void close() => _youtube.close();

  Future<String?> resolvePlayableUrl(String musicUrl) async {
    if (musicUrl.isEmpty) return null;

    final id = videoIdFrom(musicUrl);

    // googlevideo linkleri kısa ömürlü — doğrudan aday olarak kullanma; watch/videoId ile yenile.
    if (isDirectPlayableUrl(musicUrl) &&
        !musicUrl.toLowerCase().contains('googlevideo.com')) {
      return wrapForMobilePlayback(musicUrl);
    }

    if (!isYoutubePageUrl(musicUrl) &&
        !_youtubeHost.hasMatch(musicUrl) &&
        !musicUrl.toLowerCase().contains('googlevideo.com')) {
      return musicUrl;
    }

    if (id != null && id.isNotEmpty) {
      final fresh = await resolveByVideoId(id);
      if (fresh != null) return fresh;
    }

    return null;
  }

  /// videoId ile tüm kaynakları paralel dene (web Piped sırası).
  Future<String?> resolveByVideoId(String id) async {
    final trimmed = id.trim();
    if (trimmed.isEmpty) return null;

    final cached = _cache[trimmed];
    if (cached != null &&
        DateTime.now().difference(cached.at) < const Duration(minutes: 8) &&
        !cached.url.contains('googlevideo.com')) {
      return cached.url;
    }

    final watchUrl = 'https://www.youtube.com/watch?v=$trimmed';
    final results = await Future.wait<String?>([
      _resolveViaSiteApi(watchUrl),
      _resolveViaPipedParallel(trimmed),
      _resolveViaInvidiousParallel(trimmed),
      _resolveViaYoutubeExplode(trimmed),
    ]);

    for (final stream in results) {
      if (stream != null && stream.startsWith('http')) {
        final wrapped = wrapForMobilePlayback(stream);
        _remember(trimmed, wrapped);
        return wrapped;
      }
    }
    return null;
  }

  Future<String?> _resolveViaPipedParallel(String id) async {
    for (final host in _pipedHosts) {
      final piped = await _resolveViaPiped(host, id);
      if (piped != null) return piped;
    }
    return null;
  }

  Future<String?> _resolveViaInvidiousParallel(String id) async {
    for (final host in _invidiousHosts) {
      final inv = await _resolveViaInvidious(host, id);
      if (inv != null) return inv;
    }
    return null;
  }

  void _remember(String? id, String url) {
    if (id == null || id.isEmpty || !url.startsWith('http')) return;
    _cache[id] = _StreamCacheEntry(url: url, at: DateTime.now());
  }

  Future<String?> _resolveViaSiteApi(String musicUrl) async {
    try {
      final id = videoIdFrom(musicUrl);
      final res = await _dio.get<dynamic>(
        '/api/chat/youtube-stream',
        queryParameters: {
          if (id != null && id.isNotEmpty) 'videoId': id,
          'url': musicUrl,
        },
        options: Options(receiveTimeout: const Duration(seconds: 10)),
      );
      final data = res.data;
      if (data is Map) {
        for (final key in ['streamUrl', 'url', 'audioUrl']) {
          final stream = data[key];
          if (stream is String &&
              stream.startsWith('http') &&
              isDirectAudioStreamUrl(stream)) {
            return stream;
          }
        }
        // Üretim fallback: watch URL dönerse yok say (Piped dene)
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

  Future<String?> _resolveViaYoutubeExplode(String id) async {
    for (final requireWatch in [false, true]) {
      try {
        final manifest = await _youtube.videos.streamsClient
            .getManifest(VideoId(id), requireWatchPage: requireWatch)
            .timeout(const Duration(seconds: 15));
        final audio = manifest.audioOnly.toList()
          ..sort(
            (a, b) => b.bitrate.bitsPerSecond.compareTo(
              a.bitrate.bitsPerSecond,
            ),
          );
        if (audio.isEmpty) continue;
        return audio.first.url.toString();
      } catch (_) {}
    }
    return null;
  }
}

class _StreamCacheEntry {
  const _StreamCacheEntry({required this.url, required this.at});

  final String url;
  final DateTime at;
}
