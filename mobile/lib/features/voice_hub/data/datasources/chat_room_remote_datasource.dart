import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';

import '../../../../core/network/api_endpoints.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/network/dio_provider.dart';
import '../../../../core/util/json_util.dart';
import '../../domain/entities/chat_room_dj_state.dart';
import '../../domain/entities/chat_room_message.dart';
import '../../domain/entities/chat_room_presence.dart';
import '../services/voice_room_debug_log.dart';
import '../../domain/entities/music_queue_item.dart';
import '../../domain/entities/popular_music_suggestion.dart';

class ChatRoomRemoteDataSource {
  ChatRoomRemoteDataSource(this._dio);

  final Dio _dio;

  static String messagesPath(String roomId) =>
      '/api/chat/rooms/$roomId/messages';

  static String presencePath(String roomId) =>
      '/api/chat/rooms/$roomId/presence';

  static String djPath(String roomId) => '/api/chat/rooms/$roomId/dj';

  static String backgroundsPath() => '/api/chat/rooms/backgrounds';

  static String speakRequestPath(String roomId) =>
      '/api/chat/rooms/$roomId/speak-request';

  static String roomBackgroundPath(String roomId) =>
      '/api/chat/rooms/$roomId/background';

  /// canlifal.com müzik arama (mobil JWT + sunucu YOUTUBE_API_KEY).
  static String musicSearchPath() => ApiEndpoints.musicSearch;

  static String songRequestPath(String roomId) =>
      '/api/chat/rooms/$roomId/song-request';

  static String seatsPath(String roomId) => '/api/chat/rooms/$roomId/seats';

  Map<String, dynamic>? _unwrapMap(dynamic body) {
    if (body is Map<String, dynamic>) {
      if (body['success'] == true && body['data'] != null) {
        final data = body['data'];
        if (data is Map<String, dynamic>) return data;
        if (data is Map) return Map<String, dynamic>.from(data);
      }
      return body;
    }
    if (body is Map) return Map<String, dynamic>.from(body);
    return null;
  }

  List<Map<String, dynamic>> _messageList(dynamic body) {
    final map = _unwrapMap(body) ?? (body is Map ? asJsonMap(body) : null);
    if (map != null) {
      final list = map['messages'] ?? map['items'] ?? map['data'];
      if (list is List) return asJsonList(list);
    }
    if (body is List) return asJsonList(body);
    return const [];
  }

  List<ChatRoomPresence> _presenceList(dynamic body) {
    final map = _unwrapMap(body) ?? (body is Map ? asJsonMap(body) : null);
    dynamic raw;
    if (map != null) {
      raw = map['users'] ??
          map['presence'] ??
          map['members'] ??
          map['onlineUsers'] ??
          map['viewers'] ??
          map['listeners'];
      if (raw == null && map['data'] is List) raw = map['data'];
      if (raw == null && map['data'] is Map) {
        final inner = asJsonMap(map['data']);
        raw = inner['users'] ?? inner['presence'] ?? inner['members'];
      }
    } else if (body is List) {
      raw = body;
    }
    if (raw is! List) return const [];
    return raw
        .map((e) => ChatRoomPresence.fromJson(asJsonMap(e)))
        .where((u) => u.id.isNotEmpty)
        .toList();
  }

  bool _shouldTryAlternateKey(Object error, String primary, String? alternate) {
    final alt = alternate?.trim();
    if (alt == null || alt.isEmpty || alt == primary) return false;
    if (error is DioException) {
      final code = error.response?.statusCode;
      if (code == 404) return true;
      final data = error.response?.data;
      if (data is Map) {
        final msg = (data['error'] ?? data['message'] ?? '').toString();
        if (msg.contains('Oda bulunamadı')) return true;
      }
    }
    if (error is ApiException) {
      if (error.statusCode == 404) return true;
      if (error.message.contains('Oda bulunamadı')) return true;
    }
    return false;
  }

  Future<T> _withRoomKeyFallback<T>(
    String primaryKey,
    String? alternateKey,
    Future<T> Function(String key) run,
  ) async {
    try {
      return await run(primaryKey);
    } catch (e) {
      if (!_shouldTryAlternateKey(e, primaryKey, alternateKey)) rethrow;
      return await run(alternateKey!.trim());
    }
  }

  Future<List<ChatRoomMessage>> fetchMessages(
    String roomKey, {
    String? alternateKey,
    String? since,
  }) async {
    return _withRoomKeyFallback(roomKey, alternateKey, (key) async {
      final res = await _dio.safeGet<dynamic>(
        messagesPath(key),
        query: since != null && since.isNotEmpty ? {'since': since} : null,
      );
      return _messageList(res.data)
          .map(ChatRoomMessage.fromJson)
          .where((m) => m.id.isNotEmpty || m.content.isNotEmpty)
          .toList();
    });
  }

  Future<List<ChatRoomPresence>> fetchPresence(
    String roomKey, {
    String? alternateKey,
  }) async {
    return _withRoomKeyFallback(roomKey, alternateKey, (key) async {
      final res = await _dio.safeGet<dynamic>(presencePath(key));
      return _presenceList(res.data);
    });
  }

  Future<List<ChatRoomPresence>> joinPresence(
    String roomKey, {
    String? alternateKey,
  }) async {
    return _withRoomKeyFallback(roomKey, alternateKey, (key) async {
      final res = await _dio.safePost<dynamic>(presencePath(key));
      final list = _presenceList(res.data);
      VoiceRoomDebugLog.log('api.presence.post', {
        'roomId': key,
        'status': res.statusCode,
        'count': list.length,
      });
      return list;
    });
  }

  Future<void> leavePresence(
    String roomKey, {
    String? alternateKey,
  }) async {
    await _withRoomKeyFallback(roomKey, alternateKey, (key) async {
      await _dio.safeDelete<dynamic>(presencePath(key));
    });
  }

  Future<ChatRoomDjState> fetchDj(
    String roomKey, {
    String? alternateKey,
  }) async {
    return _withRoomKeyFallback(roomKey, alternateKey, (key) async {
      final res = await _dio.safeGet<dynamic>(djPath(key));
      final map = _unwrapMap(res.data) ?? asJsonMap(res.data);
      if (map.isEmpty) return const ChatRoomDjState();
      return ChatRoomDjState.fromJson(map);
    });
  }

  Future<ChatRoomDjState> updateDj({
    required String roomKey,
    String? alternateKey,
    String? musicUrl,
    required bool playing,
  }) async {
    return _withRoomKeyFallback(roomKey, alternateKey, (key) async {
      final res = await _dio.safePost<dynamic>(
        djPath(key),
        data: jsonEncode({
          if (musicUrl != null) 'musicUrl': musicUrl,
          'playing': playing,
        }),
        options: Options(contentType: 'application/json'),
      );
      final map = _unwrapMap(res.data) ?? asJsonMap(res.data);
      return ChatRoomDjState.fromJson(map);
    });
  }

  static const _fallbackBackgrounds = [
    'https://images.unsplash.com/photo-1618005182384-a83a8bd57fbe?w=1200&q=80',
    'https://images.unsplash.com/photo-1579546929518-9e396f3cc760?w=1200&q=80',
    'https://images.unsplash.com/photo-1557683316-973673baf926?w=1200&q=80',
    'https://canlifal.com/images/voice-bg-1.jpg',
    'https://canlifal.com/images/voice-bg-2.jpg',
  ];

  Future<List<String>> fetchBackgrounds() async {
    final urls = <String>{..._fallbackBackgrounds};
    try {
      final res = await _dio.safeGet<dynamic>(backgroundsPath());
      final map = _unwrapMap(res.data) ?? asJsonMap(res.data);
      final raw = map['backgrounds'] ?? map['items'];
      if (raw is List) {
        for (final e in raw) {
          final s = e.toString();
          if (s.isNotEmpty) urls.add(s);
        }
      }
    } catch (_) {}
    return urls.toList();
  }

  Future<void> advanceMusicQueue(
    String roomKey, {
    String? alternateKey,
  }) async {
    await skipMusicQueue(roomKey: roomKey, alternateKey: alternateKey);
  }

  Future<void> skipMusicQueue({
    required String roomKey,
    String? alternateKey,
  }) async {
    await _withRoomKeyFallback(roomKey, alternateKey, (key) async {
      await _dio.safePost<dynamic>(
        '/api/chat/rooms/$key/music-queue/advance',
      );
    });
  }

  Future<void> removeMusicQueueItem({
    required String roomKey,
    String? alternateKey,
    required String itemId,
  }) async {
    await _withRoomKeyFallback(roomKey, alternateKey, (key) async {
      await _dio.safeDelete<dynamic>(
        '/api/chat/rooms/$key/music-queue/$itemId',
      );
    });
  }

  Future<void> clearMusicQueue({
    required String roomKey,
    String? alternateKey,
  }) async {
    await _withRoomKeyFallback(roomKey, alternateKey, (key) async {
      await _dio.safeDelete<dynamic>('/api/chat/rooms/$key/music-queue');
    });
  }

  Future<void> updateMusicSettings({
    required String roomKey,
    String? alternateKey,
    bool? musicEnabled,
    int? musicRequestCost,
    int? maxMusicQueue,
  }) async {
    await _withRoomKeyFallback(roomKey, alternateKey, (key) async {
      await _dio.safePatch<dynamic>(
        '/api/chat/rooms/$key/music-settings',
        data: jsonEncode({
          if (musicEnabled != null) 'musicEnabled': musicEnabled,
          if (musicRequestCost != null) 'musicRequestCost': musicRequestCost,
          if (maxMusicQueue != null) 'maxMusicQueue': maxMusicQueue,
        }),
        options: Options(contentType: 'application/json'),
      );
    });
  }

  Future<List<PopularMusicSuggestion>> fetchPopularMusic() async {
    const fallback = [
      PopularMusicSuggestion(
        title: 'Tutamıyorum Zamanı',
        artist: 'Müslüm Gürses',
        query: 'Müslüm Gürses Tutamıyorum Zamanı',
        videoId: 'c9Fq8_Q5Wx8',
      ),
      PopularMusicSuggestion(
        title: 'Kum Gibi',
        artist: 'Ahmet Kaya',
        query: 'Ahmet Kaya Kum Gibi',
        videoId: '4sakaTjeb50',
      ),
      PopularMusicSuggestion(
        title: 'Yalan',
        artist: 'Tarkan',
        query: 'Tarkan Yalan',
        videoId: 'nboC0smLRsE',
      ),
    ];
    try {
      final res = await _dio.safeGet<dynamic>('/api/chat/music/popular');
      final map = _unwrapMap(res.data) ?? asJsonMap(res.data);
      final raw = map['items'];
      if (raw is List && raw.isNotEmpty) {
        return raw
            .whereType<Map>()
            .map((e) => PopularMusicSuggestion.fromJson(
                  Map<String, dynamic>.from(e),
                ))
            .toList();
      }
    } catch (_) {}
    return fallback;
  }

  Future<void> setRoomBackground({
    required String roomKey,
    String? alternateKey,
    required String backgroundImage,
  }) async {
    await _withRoomKeyFallback(roomKey, alternateKey, (key) async {
      await _dio.safePatch<dynamic>(
        roomBackgroundPath(key),
        data: jsonEncode({'backgroundImage': backgroundImage}),
      );
    });
  }

  Future<void> requestSpeak(
    String roomKey, {
    String? alternateKey,
  }) async {
    await _withRoomKeyFallback(roomKey, alternateKey, (key) async {
      await _dio.safePost<dynamic>(speakRequestPath(key));
    });
  }

  Future<void> cancelSpeakRequest(
    String roomKey, {
    String? alternateKey,
  }) async {
    await _withRoomKeyFallback(roomKey, alternateKey, (key) async {
      await _dio.safeDelete<dynamic>(speakRequestPath(key));
    });
  }

  static String banPath(String roomId, String userId) =>
      '/api/chat/rooms/$roomId/bans/$userId';

  Future<void> banUser({
    required String roomKey,
    String? alternateKey,
    required String userId,
    String? reason,
  }) async {
    await _withRoomKeyFallback(roomKey, alternateKey, (key) async {
      await _dio.safePost<dynamic>(
        banPath(key, userId),
        data: jsonEncode({if (reason != null) 'reason': reason}),
        options: Options(contentType: 'application/json'),
      );
    });
  }

  Future<void> unbanUser({
    required String roomKey,
    String? alternateKey,
    required String userId,
  }) async {
    await _withRoomKeyFallback(roomKey, alternateKey, (key) async {
      await _dio.safeDelete<dynamic>(banPath(key, userId));
    });
  }

  List<YoutubeSearchHit> _parseYoutubeHits(dynamic body) {
    dynamic raw;
    if (body is Map) {
      raw = body['items'] ??
          body['videos'] ??
          body['results'] ??
          body['data'];
      if (raw is Map) {
        raw = raw['items'] ?? raw['videos'] ?? raw['results'];
      }
    } else if (body is List) {
      raw = body;
    }
    if (raw is! List) return const [];
    final out = <YoutubeSearchHit>[];
    for (final e in raw) {
      if (e is! Map) continue;
      final m = Map<String, dynamic>.from(e);
      final vid = m['videoId']?.toString() ?? m['id']?.toString() ?? '';
      if (vid.isEmpty) continue;
      final url = m['url']?.toString() ??
          'https://www.youtube.com/watch?v=$vid';
      out.add(
        YoutubeSearchHit(
          videoId: vid,
          title: m['title']?.toString() ?? 'Video',
          url: url,
          thumbUrl: m['thumbUrl']?.toString() ??
              m['thumbnail']?.toString(),
          uploader: m['uploader']?.toString() ??
              m['channelTitle']?.toString() ??
              m['channel']?.toString(),
          duration: _formatDuration(m['duration']),
        ),
      );
    }
    return out;
  }

  String? _formatDuration(dynamic raw) {
    if (raw == null) return null;
    if (raw is String && raw.contains(':')) return raw;
    final sec = raw is num ? raw.round() : int.tryParse(raw.toString());
    if (sec == null || sec <= 0) return null;
    final m = sec ~/ 60;
    final s = sec % 60;
    return '$m:${s.toString().padLeft(2, '0')}';
  }

  Future<List<YoutubeSearchHit>> searchYoutube(String query) async {
    final q = query.trim();
    if (q.length < 2) return const [];

    final directId = _extractYoutubeId(q);
    if (directId != null) {
      return [
        YoutubeSearchHit(
          videoId: directId,
          title: 'YouTube bağlantısı',
          url: 'https://www.youtube.com/watch?v=$directId',
          thumbUrl: 'https://i.ytimg.com/vi/$directId/hqdefault.jpg',
        ),
      ];
    }

    final catalogHits = await _searchYoutubeFromPopularCatalog(q);
    if (catalogHits.isNotEmpty) return catalogHits;

    try {
      final hits = await _searchMusicViaBackend(q);
      if (hits.isNotEmpty) return hits;
    } on ApiException catch (e) {
      if (e.statusCode == 401) rethrow;
      if (e.statusCode == 503) {
        throw const ApiException(
          'Müzik araması sunucuda yapılandırılmamış. Lütfen daha sonra tekrar deneyin '
          'veya popüler listeden seçin.',
        );
      }
      rethrow;
    }

    final popularHits = await _searchYoutubeFromPopularCatalog(q);
    if (popularHits.isNotEmpty) return popularHits;

    throw const ApiException(
      'Şarkı bulunamadı. Farklı bir arama deneyin veya popüler listeden seçin.',
    );
  }

  Future<List<YoutubeSearchHit>> _searchMusicViaBackend(String q) async {
    final apiPaths = [
      musicSearchPath(),
      ApiEndpoints.youtubeSearch,
      '/api/chat/youtube-search',
    ];
    ApiException? lastApiError;
    for (final path in apiPaths) {
      try {
        final res = await _dio
            .get<dynamic>(
              path,
              queryParameters: {'q': q, 'query': q},
            )
            .timeout(const Duration(seconds: 10));
        final data = res.data;
        if (data is String &&
            (data.contains('<!DOCTYPE') || data.contains('<html'))) {
          continue;
        }
        final hits = _parseYoutubeHits(data);
        if (hits.isNotEmpty) return hits;
      } on TimeoutException {
        continue;
      } on DioException catch (e) {
        final mapped = _mapDioForYoutube(e);
        if (mapped.statusCode == 404) continue;
        lastApiError = mapped;
        if (mapped.statusCode == 401) throw mapped;
      } on ApiException catch (e) {
        if (e.statusCode == 404) continue;
        lastApiError = e;
        if (e.statusCode == 401) rethrow;
      }
      try {
        final res = await _dio
            .safePost<dynamic>(
              path,
              data: {'q': q, 'query': q},
              options: Options(contentType: 'application/json'),
            )
            .timeout(const Duration(seconds: 10));
        final hits = _parseYoutubeHits(res.data);
        if (hits.isNotEmpty) return hits;
      } on TimeoutException {
        continue;
      } on ApiException catch (e) {
        lastApiError = e;
        if (e.statusCode == 401) rethrow;
      }
    }
    if (lastApiError != null) throw lastApiError;
    return const [];
  }

  ApiException _mapDioForYoutube(DioException e) {
    final status = e.response?.statusCode;
    final body = e.response?.data;
    var msg = e.message ?? 'İstek başarısız';
    if (body is Map) {
      final m = body['message'] ?? body['error'];
      if (m is String && m.isNotEmpty) msg = m;
    }
    return ApiException(msg, statusCode: status);
  }

  Future<List<YoutubeSearchHit>> _searchYoutubeFromPopularCatalog(String q) async {
    final lower = q.toLowerCase();
    final popular = await fetchPopularMusic();
    final matches = popular
        .where(
          (p) =>
              p.title.toLowerCase().contains(lower) ||
              p.artist.toLowerCase().contains(lower) ||
              p.query.toLowerCase().contains(lower),
        )
        .take(6)
        .toList();
    if (matches.isEmpty) return const [];

    final withIds = <YoutubeSearchHit>[];
    for (final m in matches) {
      final hit = m.toSearchHit();
      if (hit != null) withIds.add(hit);
    }
    return withIds;
  }

  /// Üretimde komut işlenmezse sohbeti temizlemek için dene.
  Future<void> tryClearRoomMessages({
    required String roomKey,
    String? alternateKey,
  }) async {
    try {
      await _withRoomKeyFallback(roomKey, alternateKey, (key) async {
        await _dio.safeDelete<dynamic>(messagesPath(key));
      });
    } catch (_) {}
  }

  Future<
      ({
        List<MusicQueueItem> queue,
        int cost,
        int maxMusicQueue,
        bool musicEnabled,
        MusicQueueItem? nowPlaying,
        bool playing,
        bool canRequestMusic,
      })> fetchMusicQueue(
    String roomKey, {
    String? alternateKey,
  }) async {
    return _withRoomKeyFallback(roomKey, alternateKey, (key) async {
      Response<dynamic> res;
      try {
        res = await _dio.safeGet<dynamic>(songRequestPath(key));
      } on Object {
        res = await _dio.safeGet<dynamic>('/api/chat/rooms/$key/music-queue');
      }
      final map = _unwrapMap(res.data) ?? asJsonMap(res.data);
      final raw = map['queue'] ?? map['items'];
      final queue = <MusicQueueItem>[];
      if (raw is List) {
        for (final e in raw) {
          if (e is Map) {
            queue.add(MusicQueueItem.fromJson(Map<String, dynamic>.from(e)));
          }
        }
      }
      final cost = map['cost'] as int? ??
          map['musicRequestCost'] as int? ??
          10;
      MusicQueueItem? nowPlaying;
      final np = map['nowPlaying'];
      if (np is Map) {
        nowPlaying = MusicQueueItem.fromJson(Map<String, dynamic>.from(np));
      } else if (map['playing'] == true && queue.isNotEmpty) {
        nowPlaying = queue.first;
      }
      return (
        queue: queue,
        cost: cost,
        maxMusicQueue: map['maxMusicQueue'] as int? ?? 20,
        musicEnabled: map['musicEnabled'] != false,
        nowPlaying: nowPlaying,
        playing: map['playing'] == true,
        canRequestMusic: map['canRequestMusic'] == true,
      );
    });
  }

  Future<
      ({
        MusicQueueItem? item,
        List<MusicQueueItem> queue,
        int? newBalance,
        int? queuePosition,
      })> requestMusic({
    required String roomKey,
    String? alternateKey,
    required String title,
    required String youtubeUrl,
    String? thumbUrl,
    String? videoId,
    String? giftTo,
    String? note,
  }) async {
    return _withRoomKeyFallback(roomKey, alternateKey, (key) async {
      final vid = videoId?.trim().isNotEmpty == true
          ? videoId!.trim()
          : _extractYoutubeId(youtubeUrl);
      final body = jsonEncode({
        'title': title,
        'youtubeUrl': youtubeUrl,
        if (vid != null) 'videoId': vid,
        if (thumbUrl != null) 'thumbUrl': thumbUrl,
        if (giftTo != null && giftTo.trim().isNotEmpty)
          'giftTo': giftTo.trim(),
        if (note != null && note.trim().isNotEmpty) 'note': note.trim(),
      });
      final opts = Options(contentType: 'application/json');
      Response<dynamic> res;
      try {
        res = await _dio.safePost<dynamic>(
          songRequestPath(key),
          data: body,
          options: opts,
        );
      } on Object {
        res = await _dio.safePost<dynamic>(
          '/api/chat/rooms/$key/music-queue',
          data: body,
          options: opts,
        );
      }
      final map = _unwrapMap(res.data) ?? asJsonMap(res.data);
      MusicQueueItem? item;
      final itemRaw = map['item'];
      if (itemRaw is Map) {
        item = MusicQueueItem.fromJson(Map<String, dynamic>.from(itemRaw));
      }
      final queueRaw = map['queue'];
      final queue = <MusicQueueItem>[];
      if (queueRaw is List) {
        for (final e in queueRaw) {
          if (e is Map) {
            queue.add(MusicQueueItem.fromJson(Map<String, dynamic>.from(e)));
          }
        }
      }
      final balance = map['newBalance'] as int? ?? map['coinBalance'] as int?;
      final position = map['queuePosition'] as int?;
      return (
        item: item,
        queue: queue,
        newBalance: balance,
        queuePosition: position,
      );
    });
  }

  Future<void> assignSeat({
    required String roomKey,
    String? alternateKey,
    required int seatIndex,
    String? userId,
  }) async {
    final body = jsonEncode({
      'seatIndex': seatIndex,
      if (userId != null && userId.isNotEmpty) 'userId': userId,
    });
    final opts = Options(contentType: 'application/json');
    await _withRoomKeyFallback(roomKey, alternateKey, (key) async {
      try {
        await _dio.safePatch<dynamic>(
          seatsPath(key),
          data: body,
          options: opts,
        );
        return;
      } on ApiException catch (e) {
        if (e.statusCode != 405 && e.statusCode != 404) rethrow;
      }
      await _dio.safePost<dynamic>(
        seatsPath(key),
        data: body,
        options: opts,
      );
    });
  }

  Future<List<String>> addRoomDj({
    required String roomKey,
    String? alternateKey,
    required String targetUserId,
  }) async {
    return _withRoomKeyFallback(roomKey, alternateKey, (key) async {
      Response<dynamic> res;
      try {
        res = await _dio.safePost<dynamic>(
          '/api/chat/rooms/$key/dj/$targetUserId',
        );
      } on Object {
        res = await _dio.safePost<dynamic>(
          djPath(key),
          data: jsonEncode({'userId': targetUserId, 'action': 'add'}),
          options: Options(contentType: 'application/json'),
        );
      }
      final map = _unwrapMap(res.data) ?? asJsonMap(res.data);
      final raw = map['djUserIds'];
      if (raw is List) return raw.map((e) => e.toString()).toList();
      return const [];
    });
  }

  Future<List<String>> removeRoomDj({
    required String roomKey,
    String? alternateKey,
    required String targetUserId,
  }) async {
    return _withRoomKeyFallback(roomKey, alternateKey, (key) async {
      Response<dynamic> res;
      try {
        res = await _dio.safeDelete<dynamic>(
          '/api/chat/rooms/$key/dj/$targetUserId',
        );
      } on Object {
        res = await _dio.safePost<dynamic>(
          djPath(key),
          data: jsonEncode({'userId': targetUserId, 'action': 'remove'}),
          options: Options(contentType: 'application/json'),
        );
      }
      final map = _unwrapMap(res.data) ?? asJsonMap(res.data);
      final raw = map['djUserIds'];
      if (raw is List) return raw.map((e) => e.toString()).toList();
      return const [];
    });
  }

  Future<List<String>> fetchBannedWords(
    String roomKey, {
    String? alternateKey,
  }) async {
    return _withRoomKeyFallback(roomKey, alternateKey, (key) async {
      final res = await _dio.safeGet<dynamic>(
        '/api/chat/rooms/$key/banned-words',
      );
      final map = _unwrapMap(res.data) ?? asJsonMap(res.data);
      final raw = map['words'];
      if (raw is List) {
        return raw.map((e) => e.toString()).where((s) => s.isNotEmpty).toList();
      }
      return const [];
    });
  }

  Future<List<String>> addBannedWord({
    required String roomKey,
    String? alternateKey,
    required String word,
  }) async {
    return _withRoomKeyFallback(roomKey, alternateKey, (key) async {
      final res = await _dio.safePost<dynamic>(
        '/api/chat/rooms/$key/banned-words',
        data: jsonEncode({'word': word}),
        options: Options(contentType: 'application/json'),
      );
      final map = _unwrapMap(res.data) ?? asJsonMap(res.data);
      final raw = map['words'];
      if (raw is List) {
        return raw.map((e) => e.toString()).toList();
      }
      return const [];
    });
  }

  Future<List<String>> removeBannedWord({
    required String roomKey,
    String? alternateKey,
    required String word,
  }) async {
    return _withRoomKeyFallback(roomKey, alternateKey, (key) async {
      final encoded = Uri.encodeComponent(word);
      final res = await _dio.safeDelete<dynamic>(
        '/api/chat/rooms/$key/banned-words/$encoded',
      );
      final map = _unwrapMap(res.data) ?? asJsonMap(res.data);
      final raw = map['words'];
      if (raw is List) {
        return raw.map((e) => e.toString()).toList();
      }
      return const [];
    });
  }

  String? _extractYoutubeId(String url) {
    final u = url.trim();
    if (u.isEmpty) return null;
    final short = RegExp(r'youtu\.be/([A-Za-z0-9_-]{6,})');
    final watch = RegExp(r'[?&]v=([A-Za-z0-9_-]{6,})');
    return short.firstMatch(u)?.group(1) ?? watch.firstMatch(u)?.group(1);
  }

  Future<ChatRoomMessage?> sendMessage({
    required String roomKey,
    String? alternateKey,
    required String content,
  }) async {
    return _withRoomKeyFallback(roomKey, alternateKey, (key) async {
      final res = await _dio.safePost<dynamic>(
        messagesPath(key),
        data: jsonEncode({
          'content': content,
          'body': content,
          'message': content,
          'text': content,
        }),
        options: Options(contentType: 'application/json'),
      ).timeout(const Duration(seconds: 15));
      final code = res.statusCode ?? 0;
      if (code >= 200 && code < 300) {
        final body = res.data;
        if (body is String &&
            (body.contains('<!DOCTYPE') || body.contains('<html'))) {
          throw const ApiException('Mesaj gönderilemedi (oturum gerekli).');
        }
        if (body is Map) {
          final map = _unwrapMap(body) ?? asJsonMap(body);
          if (map['success'] == false) {
            throw ApiException(
              (map['error'] ?? map['message'] ?? 'Mesaj gönderilemedi')
                  .toString(),
            );
          }
          final msg = map['message'];
          if (msg is Map) {
            return ChatRoomMessage.fromJson(Map<String, dynamic>.from(msg));
          }
          if (map['id'] != null &&
              (map['content'] != null ||
                  map['body'] != null ||
                  map['text'] != null)) {
            return ChatRoomMessage.fromJson(map);
          }
        }
        return ChatRoomMessage(
          id: 'srv-${DateTime.now().millisecondsSinceEpoch}',
          content: content,
          createdAt: DateTime.now(),
        );
      }
      final errBody = res.data;
      if (errBody is Map) {
        final m = asJsonMap(errBody);
        throw ApiException(
          (m['error'] ?? m['message'] ?? 'Mesaj gönderilemedi ($code)')
              .toString(),
          statusCode: code,
        );
      }
      throw ApiException('Mesaj gönderilemedi (HTTP $code)', statusCode: code);
    });
  }
}
