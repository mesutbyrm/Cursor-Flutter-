import 'dart:async';

import 'package:dio/dio.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';

/// YouTube watch URL → doğrudan ses akışı (site API + explode + Piped + Invidious).
class YoutubeStreamResolver {
  YoutubeStreamResolver(this._dio);

  final Dio _dio;
  YoutubeExplode? _explode;

  static final _youtubeHost = RegExp(r'youtube\.com|youtu\.be', caseSensitive: false);

  static const _cacheTtl = Duration(hours: 2);

  static const _pipedHosts = [
    'https://pipedapi.kavin.rocks',
    'https://pipedapi.adminforge.de',
    'https://pipedapi.syncpundit.io',
    'https://pipedapi.leptons.xyz',
    'https://pipedapi.in.projectsegfau.lt',
    'https://pipedapi.moomoo.me',
    'https://api.piped.projectsegfau.lt',
  ];

  static const _invidiousHosts = [
    'https://invidious.nerdvpn.de',
    'https://invidious.privacyredirect.com',
    'https://invidious.fdn.fr',
    'https://invidious.dhus.de',
    'https://invidious.io.lol',
    'https://inv.tux.pizza',
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

  /// Arama/istek öncesi akışı önbelleğe alır.
  Future<String?> prefetch(String musicUrl) => resolvePlayableUrl(musicUrl);

  Future<String?> resolvePlayableUrl(String musicUrl) async {
    if (musicUrl.isEmpty) return null;
    if (isDirectPlayableUrl(musicUrl)) return musicUrl;
    if (!_youtubeHost.hasMatch(musicUrl)) return musicUrl;

    final id = videoIdFrom(musicUrl);
    if (id != null && id.isNotEmpty) {
      final cached = _cache[id];
      if (cached != null &&
          DateTime.now().difference(cached.at) < _cacheTtl) {
        return cached.url;
      }
    }

    final futures = <Future<String?>>[
      _resolveViaSiteApi(musicUrl),
      if (id != null && id.isNotEmpty) _resolveViaExplode(id),
      if (id != null && id.isNotEmpty)
        _firstSuccess(
          _pipedHosts.map((h) => _resolveViaPiped(h, id)),
          timeout: const Duration(seconds: 8),
        ),
      if (id != null && id.isNotEmpty)
        _firstSuccess(
          _invidiousHosts.map((h) => _resolveViaInvidious(h, id)),
          timeout: const Duration(seconds: 8),
        ),
    ];

    final winner = await _firstSuccess(futures, timeout: const Duration(seconds: 12));
    if (winner != null) {
      _remember(id, winner);
      return winner;
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
    for (var i = 0; i < 2; i++) {
      try {
        final res = await _dio.get<dynamic>(
          '/api/chat/youtube-stream',
          queryParameters: {'url': musicUrl},
          options: Options(receiveTimeout: const Duration(seconds: 10)),
        );
        final data = res.data;
        if (data is Map) {
          final stream = data['streamUrl'] ?? data['url'];
          if (stream is String && stream.startsWith('http')) return stream;
        }
      } catch (_) {}
      if (i == 0) await Future<void>.delayed(const Duration(milliseconds: 350));
    }
    return null;
  }

  Future<String?> _resolveViaExplode(String id) async {
    try {
      _explode ??= YoutubeExplode();
      final manifest = await _explode!.videos.streamsClient.getManifest(id);
      final audio = manifest.audioOnly.withHighestBitrate();
      final url = audio.url.toString();
      if (url.startsWith('http')) return url;
    } catch (_) {}
    return null;
  }

  Future<String?> _resolveViaPiped(String host, String id) async {
    try {
      final res = await _dio.get<dynamic>(
        '$host/streams/$id',
        options: Options(
          headers: {'Accept': 'application/json'},
          receiveTimeout: const Duration(seconds: 6),
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
          receiveTimeout: const Duration(seconds: 6),
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

  void dispose() {
    _explode?.close();
    _explode = null;
  }
}

class _StreamCacheEntry {
  const _StreamCacheEntry({required this.url, required this.at});

  final String url;
  final DateTime at;
}
