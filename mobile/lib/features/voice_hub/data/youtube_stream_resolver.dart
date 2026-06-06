import 'package:dio/dio.dart';

/// YouTube watch URL → doğrudan ses akışı (site API + Piped + Invidious).
class YoutubeStreamResolver {
  YoutubeStreamResolver(this._dio);

  final Dio _dio;

  static final _youtubeHost = RegExp(r'youtube\.com|youtu\.be', caseSensitive: false);

  static const _pipedHosts = [
    'https://pipedapi.kavin.rocks',
    'https://pipedapi.adminforge.de',
    'https://pipedapi.syncpundit.io',
    'https://pipedapi.leptons.xyz',
    'https://pipedapi.in.projectsegfau.lt',
  ];

  static const _invidiousHosts = [
    'https://invidious.nerdvpn.de',
    'https://invidious.privacyredirect.com',
    'https://invidious.fdn.fr',
    'https://invidious.dhus.de',
  ];

  bool needsResolve(String url) => _youtubeHost.hasMatch(url);

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

  Future<String?> resolvePlayableUrl(String musicUrl) async {
    if (musicUrl.isEmpty) return null;
    if (!_youtubeHost.hasMatch(musicUrl)) return musicUrl;

    final fromApi = await _resolveViaSiteApi(musicUrl);
    if (fromApi != null) return fromApi;

    final id = videoIdFrom(musicUrl);
    if (id == null || id.isEmpty) return null;

    for (final host in _pipedHosts) {
      final url = await _resolveViaPiped(host, id);
      if (url != null) return url;
    }
    for (final host in _invidiousHosts) {
      final url = await _resolveViaInvidious(host, id);
      if (url != null) return url;
    }
    return null;
  }

  Future<String?> _resolveViaSiteApi(String musicUrl) async {
    try {
      final res = await _dio.get<dynamic>(
        '/api/chat/youtube-stream',
        queryParameters: {'url': musicUrl},
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
          receiveTimeout: const Duration(seconds: 12),
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
          receiveTimeout: const Duration(seconds: 12),
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
