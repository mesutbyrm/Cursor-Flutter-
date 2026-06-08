import 'dart:async';

import 'package:dio/dio.dart';

/// YouTube watch URL → doğrudan ses akışı (site API + Piped + Invidious).
class YoutubeStreamResolver {
  YoutubeStreamResolver(this._dio);

  final Dio _dio;

  static final _youtubeHost = RegExp(r'youtube\.com|youtu\.be', caseSensitive: false);

  static const _cacheTtl = Duration(hours: 3);

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

  final Map<String, _StreamCacheEntry> _cache = {};

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

  /// Arama/istek öncesi akışı önbelleğe alır.
  Future<String?> prefetch(String musicUrl) => resolvePlayableUrl(musicUrl);

  Future<String?> resolvePlayableUrl(String musicUrl) async {
    if (musicUrl.isEmpty) return null;
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
      _remember(id, fromApi);
      return fromApi;
    }

    if (id == null || id.isEmpty) return null;

    final piped = await _firstSuccess(
      _pipedHosts.map((h) => _resolveViaPiped(h, id)),
      timeout: const Duration(seconds: 6),
    );
    if (piped != null) {
      _remember(id, piped);
      return piped;
    }

    final invidious = await _firstSuccess(
      _invidiousHosts.map((h) => _resolveViaInvidious(h, id)),
      timeout: const Duration(seconds: 6),
    );
    if (invidious != null) {
      _remember(id, invidious);
      return invidious;
    }
    return null;
  }

  void _remember(String? id, String url) {
    if (id == null || id.isEmpty || !url.startsWith('http')) return;
    _cache[id] = _StreamCacheEntry(url: url, at: DateTime.now());
  }

  Future<String?> _firstSuccess(
    Iterable<Future<String?>> futures, {
    required Duration timeout,
  }) async {
    if (futures.isEmpty) return null;
    final completer = Completer<String?>();
    var pending = 0;
    for (final future in futures) {
      pending++;
      future.then((value) {
        if (value != null && value.isNotEmpty && !completer.isCompleted) {
          completer.complete(value);
        }
        pending--;
        if (pending == 0 && !completer.isCompleted) {
          completer.complete(null);
        }
      }).catchError((_) {
        pending--;
        if (pending == 0 && !completer.isCompleted) {
          completer.complete(null);
        }
      });
    }
    try {
      return await completer.future.timeout(timeout, onTimeout: () => null);
    } catch (_) {
      return null;
    }
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
