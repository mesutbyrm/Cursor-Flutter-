import 'dart:convert';

import 'package:dio/dio.dart';

import '../../../../core/network/dio_provider.dart';
import '../../../../core/util/json_util.dart';
import '../../domain/entities/chat_room_dj_state.dart';
import '../../domain/entities/chat_room_message.dart';
import '../../domain/entities/chat_room_presence.dart';
import '../../domain/entities/music_queue_item.dart';

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

  static String youtubeSearchPath() => '/api/chat/youtube-search';

  static String musicQueuePath(String roomId) =>
      '/api/chat/rooms/$roomId/music-queue';

  static String roomDjUserPath(String roomId, String userId) =>
      '/api/chat/rooms/$roomId/dj/$userId';

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
          map['onlineUsers'];
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

  Future<T> _withRoomKeyFallback<T>(
    String primaryKey,
    String? alternateKey,
    Future<T> Function(String key) run,
  ) async {
    try {
      return await run(primaryKey);
    } on DioException catch (e) {
      final alt = alternateKey?.trim();
      if (alt == null ||
          alt.isEmpty ||
          alt == primaryKey ||
          e.response?.statusCode != 404) {
        rethrow;
      }
      return await run(alt);
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
      return _presenceList(res.data);
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

  Future<List<String>> fetchBackgrounds() async {
    final res = await _dio.safeGet<dynamic>(backgroundsPath());
    final map = _unwrapMap(res.data) ?? asJsonMap(res.data);
    final raw = map['backgrounds'] ?? map['items'];
    if (raw is! List) return const [];
    return raw.map((e) => e.toString()).where((s) => s.isNotEmpty).toList();
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

  Future<List<YoutubeSearchHit>> searchYoutube(String query) async {
    final q = query.trim();
    if (q.length < 2) return const [];
    final res = await _dio.safeGet<dynamic>(
      youtubeSearchPath(),
      query: {'q': q},
    );
    final body = res.data;
    dynamic raw;
    if (body is Map) {
      raw = body['items'] ?? body['data'];
      if (raw == null && body['success'] == true) {
        final data = body['data'];
        if (data is Map) raw = data['items'];
      }
    }
    if (raw is! List) return const [];
    return raw
        .map((e) => YoutubeSearchHit.fromJson(asJsonMap(e)))
        .where((h) => h.videoId.isNotEmpty)
        .toList();
  }

  Future<({List<MusicQueueItem> queue, int cost})> fetchMusicQueue(
    String roomKey, {
    String? alternateKey,
  }) async {
    return _withRoomKeyFallback(roomKey, alternateKey, (key) async {
      final res = await _dio.safeGet<dynamic>(musicQueuePath(key));
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
      final cost = map['cost'] as int? ?? 10;
      return (queue: queue, cost: cost);
    });
  }

  Future<({MusicQueueItem? item, List<MusicQueueItem> queue, int? newBalance})>
      requestMusic({
    required String roomKey,
    String? alternateKey,
    required String title,
    required String youtubeUrl,
    String? thumbUrl,
  }) async {
    return _withRoomKeyFallback(roomKey, alternateKey, (key) async {
      final res = await _dio.safePost<dynamic>(
        musicQueuePath(key),
        data: jsonEncode({
          'title': title,
          'youtubeUrl': youtubeUrl,
          if (thumbUrl != null) 'thumbUrl': thumbUrl,
        }),
        options: Options(contentType: 'application/json'),
      );
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
      return (item: item, queue: queue, newBalance: balance);
    });
  }

  Future<List<String>> addRoomDj({
    required String roomKey,
    String? alternateKey,
    required String targetUserId,
  }) async {
    return _withRoomKeyFallback(roomKey, alternateKey, (key) async {
      final res = await _dio.safePost<dynamic>(roomDjUserPath(key, targetUserId));
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
      final res =
          await _dio.safeDelete<dynamic>(roomDjUserPath(key, targetUserId));
      final map = _unwrapMap(res.data) ?? asJsonMap(res.data);
      final raw = map['djUserIds'];
      if (raw is List) return raw.map((e) => e.toString()).toList();
      return const [];
    });
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
      );
      final body = res.data;
      if (body is Map) {
        final map = _unwrapMap(body) ?? asJsonMap(body);
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
      return null;
    });
  }
}
