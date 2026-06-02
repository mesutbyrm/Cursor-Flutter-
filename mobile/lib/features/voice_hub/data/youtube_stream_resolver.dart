import 'package:dio/dio.dart';

/// YouTube watch URL → doğrudan ses akışı (Piped / site API).
class YoutubeStreamResolver {
  YoutubeStreamResolver(this._dio);

  final Dio _dio;

  static final _youtubeHost = RegExp(r'youtube\.com|youtu\.be', caseSensitive: false);

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

    final id = videoIdFrom(musicUrl);
    if (id == null || id.isEmpty) return null;
    try {
      final res = await _dio.get<dynamic>(
        'https://pipedapi.kavin.rocks/streams/$id',
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
}
