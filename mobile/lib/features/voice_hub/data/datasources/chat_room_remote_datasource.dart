import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';

import '../../../../core/network/api_endpoints.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/network/dio_provider.dart';
import '../../../../core/util/json_util.dart';
import '../../../live/data/datasources/live_field/live_field_api_remote_datasource.dart';
import '../../domain/voice_room_background_catalog.dart';
import '../../domain/entities/chat_room_dj_state.dart';
import '../../domain/entities/chat_room_message.dart';
import '../../domain/entities/chat_room_presence.dart';
import '../services/voice_room_debug_log.dart';
import '../services/voice_room_music_pipeline_log.dart';
import '../youtube_music_search_cache.dart';
import '../../domain/entities/music_queue_item.dart';
import '../../domain/entities/moderation_result.dart';
import '../../domain/entities/voice_room_ban_entry.dart';
import '../../domain/entities/popular_music_suggestion.dart';
import '../../domain/entities/chat_room_my_permissions.dart';

class ChatRoomRemoteDataSource {
  ChatRoomRemoteDataSource(this._dio, {YoutubeMusicSearchCache? searchCache})
      : _searchCache = searchCache ?? YoutubeMusicSearchCache();

  final Dio _dio;
  final YoutubeMusicSearchCache _searchCache;

  LiveFieldApiRemoteDataSource get _liveField => LiveFieldApiRemoteDataSource(_dio);
  final YoutubeExplode _youtube = YoutubeExplode();

  void close() => _youtube.close();

  static String messagesPath(String roomId) =>
      '/api/chat/rooms/$roomId/messages';

  static String presencePath(String roomId) =>
      '/api/chat/rooms/$roomId/presence';

  static String djPath(String roomId) => '/api/chat/rooms/$roomId/dj';

  static String musicPath(String roomId) => '/api/chat/rooms/$roomId/music';

  static String moderationPath(String roomId) =>
      '/api/chat/rooms/$roomId/moderation';

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

  static String voicePath(String roomId) => ApiEndpoints.chatRoomVoice(roomId);

  static String typingPath(String roomId) => ApiEndpoints.chatRoomTyping(roomId);

  /// Üretim presence/voice — kılavuz §9.3 (`action` join/leave, heartbeat PATCH).
  static const presenceHeartbeatInterval = Duration(seconds: 12);

  /// Heartbeat — `PATCH /presence` (kılavuz §9.3 / üretim).
  Future<void> presenceHeartbeat(
    String roomKey, {
    String? alternateKey,
  }) async {
    await _withRoomKeyFallback(roomKey, alternateKey, (key) async {
      try {
        await _dio.safePatch<dynamic>(presencePath(key));
        return;
      } on ApiException catch (e) {
        if (e.statusCode != 404 && e.statusCode != 405) rethrow;
      }
      // Eski backend: boş POST da heartbeat kabul edebilir.
      await _dio.safePost<dynamic>(
        presencePath(key),
        data: const {'action': 'heartbeat'},
      );
    });
  }

  /// Odaya giriş: join + presence listesi (kılavuz §9.3).
  Future<List<ChatRoomPresence>> enterPresence(
    String roomKey, {
    String? alternateKey,
    String? nickname,
  }) async {
    return joinPresence(
      roomKey,
      alternateKey: alternateKey,
      nickname: nickname,
    );
  }

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
      raw =
          map['users'] ??
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

  Future<
    ({
      List<ChatRoomMessage> messages,
      ChatRoomMyPermissions? myPermissions,
      String? myNickname,
      bool? roomMuted,
    })
  >
  fetchMessages(
    String roomKey, {
    String? alternateKey,
    String? since,
    int limit = 100,
  }) async {
    Future<({
      ChatRoomMyPermissions? myPermissions,
      String? myNickname,
      bool? roomMuted,
    })> loadMeta() =>
        _fetchRoomMeta(roomKey, alternateKey: alternateKey);

    try {
      final liveMsgs = await _liveField.messages.fetchMessages(
        roomId: roomKey,
        roomType: 'voice',
        after: since,
        limit: limit,
      );
      if (liveMsgs.isNotEmpty) {
        final messages = liveMsgs
            .map(
              (m) => ChatRoomMessage(
                id: m.id,
                content: m.content,
                createdAt: m.createdAt ?? DateTime.now(),
                user: ChatRoomUserRef(
                  id: m.userId ?? '',
                  name: m.userName ?? 'Kullanıcı',
                  image: m.userImage,
                  chatRole: m.chatRole,
                  roleSymbol: m.roleSymbol,
                ),
              ),
            )
            .where((m) => m.id.isNotEmpty || m.content.isNotEmpty)
            .toList();
        final meta = await loadMeta();
        return (
          messages: messages,
          myPermissions: meta.myPermissions,
          myNickname: meta.myNickname,
          roomMuted: meta.roomMuted,
        );
      }
    } on ApiException catch (e) {
      if (e.statusCode != 404 && e.statusCode != 405) rethrow;
    } catch (_) {}

    return _withRoomKeyFallback(roomKey, alternateKey, (key) async {
      final cursor = since?.trim();
      final query = <String, dynamic>{
        'limit': limit,
        if (cursor != null && cursor.isNotEmpty) ...{
          'after': cursor,
          'since': cursor,
        },
      };
      final res = await _dio.safeGet<dynamic>(
        messagesPath(key),
        query: query,
      );
      final body = res.data;
      final map = _unwrapMap(body) ?? (body is Map ? asJsonMap(body) : null);
      ChatRoomMyPermissions? perms;
      String? myNickname;
      bool? roomMuted;
      if (map != null) {
        final rawPerms = map['myPermissions'];
        if (rawPerms is Map) {
          perms = ChatRoomMyPermissions.fromJson(
            Map<String, dynamic>.from(rawPerms),
          );
        }
        myNickname = map['myNickname']?.toString();
        final muted = map['roomMuted'];
        if (muted is bool) roomMuted = muted;
      }
      final messages = _messageList(body)
          .map(ChatRoomMessage.fromJson)
          .where((m) => m.id.isNotEmpty || m.content.isNotEmpty)
          .toList();
      return (
        messages: messages,
        myPermissions: perms,
        myNickname: myNickname,
        roomMuted: roomMuted,
      );
    });
  }

  /// Yalnızca `myPermissions` / rumuz — mesaj listesi olmadan.
  Future<ChatRoomMyPermissions?> fetchMyPermissions(
    String roomKey, {
    String? alternateKey,
  }) async {
    final meta = await _fetchRoomMeta(roomKey, alternateKey: alternateKey);
    return meta.myPermissions;
  }

  Future<
    ({
      ChatRoomMyPermissions? myPermissions,
      String? myNickname,
      bool? roomMuted,
    })
  > _fetchRoomMeta(
    String roomKey, {
    String? alternateKey,
  }) async {
    try {
      return await _withRoomKeyFallback(roomKey, alternateKey, (key) async {
        final res = await _dio.safeGet<dynamic>(
          messagesPath(key),
          query: const {'limit': 1},
        );
        final body = res.data;
        final map =
            _unwrapMap(body) ?? (body is Map ? asJsonMap(body) : null);
        ChatRoomMyPermissions? perms;
        String? myNickname;
        bool? roomMuted;
        if (map != null) {
          final rawPerms = map['myPermissions'];
          if (rawPerms is Map) {
            perms = ChatRoomMyPermissions.fromJson(
              Map<String, dynamic>.from(rawPerms),
            );
          }
          myNickname = map['myNickname']?.toString();
          final muted = map['roomMuted'];
          if (muted is bool) roomMuted = muted;
        }
        return (
          myPermissions: perms,
          myNickname: myNickname,
          roomMuted: roomMuted,
        );
      });
    } catch (_) {
      return (
        myPermissions: null,
        myNickname: null,
        roomMuted: null,
      );
    }
  }

  Future<List<ChatRoomPresence>> fetchPresence(
    String roomKey, {
    String? alternateKey,
  }) async {
    try {
      final page = await _liveField.onlineUsers.fetchOnlineUsers(
        roomId: roomKey,
        roomType: 'voice',
      );
      if (page.users.isNotEmpty) {
        return page.users
            .map(
              (u) => ChatRoomPresence(
                id: u.userId,
                name: u.userName ?? u.nickname ?? 'Kullanıcı',
                nickname: u.nickname,
                image: u.userImage,
                seatIndex: u.seatIndex,
                isMuted: !u.isMicOn,
              ),
            )
            .where((p) => p.id.isNotEmpty)
            .toList();
      }
    } on ApiException catch (e) {
      if (e.statusCode != 404 && e.statusCode != 405) rethrow;
    } catch (_) {}

    return _withRoomKeyFallback(roomKey, alternateKey, (key) async {
      final res = await _dio.safeGet<dynamic>(presencePath(key));
      return _presenceList(res.data);
    });
  }

  Future<List<ChatRoomPresence>> joinPresence(
    String roomKey, {
    String? alternateKey,
    String? nickname,
    int? seatIndex,
    String? password,
  }) async {
    return _withRoomKeyFallback(roomKey, alternateKey, (key) async {
      final nick = nickname?.trim();
      final pass = password?.trim();
      final bodies = <Map<String, dynamic>>[
        {
          'action': 'join',
          if (nick != null && nick.isNotEmpty) 'nickname': nick,
          if (seatIndex != null && seatIndex >= 0) 'seatIndex': seatIndex,
          if (pass != null && pass.isNotEmpty) ...{
            'password': pass,
            'entryPassword': pass,
          },
        },
        if (nick != null && nick.isNotEmpty)
          {
            'action': 'join',
            if (pass != null && pass.isNotEmpty) ...{
              'password': pass,
              'entryPassword': pass,
            },
          },
        {
          'type': 'join',
          if (nick != null && nick.isNotEmpty) 'nickname': nick,
          if (pass != null && pass.isNotEmpty) 'password': pass,
        },
      ];
      ApiException? lastError;
      for (final body in bodies) {
        try {
          final res = await _dio.safePost<dynamic>(
            presencePath(key),
            data: body,
          );
          final list = _presenceList(res.data);
          VoiceRoomDebugLog.log('api.presence.post', {
            'roomId': key,
            'status': res.statusCode,
            'count': list.length,
            'seatIndex': ?seatIndex,
            'bodyKeys': body.keys.toList(),
          });
          return list;
        } on ApiException catch (e) {
          lastError = e;
          final msg = e.message.toLowerCase();
          if (e.statusCode == 400 ||
              e.statusCode == 422 ||
              msg.contains('invalid type')) {
            continue;
          }
          rethrow;
        }
      }
      if (lastError != null) {
        // POST gövdesi reddedilse bile GET ile mevcut presence alınabilir.
        try {
          final res = await _dio.safeGet<dynamic>(presencePath(key));
          final list = _presenceList(res.data);
          if (list.isNotEmpty) return list;
        } catch (_) {}
        throw lastError;
      }
      return const [];
    });
  }

  Future<void> leavePresence(String roomKey, {String? alternateKey}) async {
    await _withRoomKeyFallback(roomKey, alternateKey, (key) async {
      try {
        await _dio.safeDelete<dynamic>('${presencePath(key)}?leave=1');
        return;
      } on ApiException catch (e) {
        if (e.statusCode != 404 && e.statusCode != 405) rethrow;
      } catch (_) {}
      try {
        await _dio.safePost<dynamic>(
          presencePath(key),
          data: const {'action': 'leave'},
        );
        return;
      } on ApiException catch (e) {
        if (e.statusCode != 404 && e.statusCode != 405) rethrow;
      } catch (_) {}
      try {
        await _dio.safePost<dynamic>(
          presencePath(key),
          data: const {'type': 'leave'},
        );
      } catch (_) {}
    });
  }

  Future<void> joinVoiceSession(String roomKey, {String? alternateKey}) async {
    await _withRoomKeyFallback(roomKey, alternateKey, (key) async {
      final bodies = <Map<String, dynamic>>[
        const {'action': 'join'},
        const {'type': 'join'},
        const {'action': 'join', 'type': 'join'},
      ];
      ApiException? lastError;
      for (final body in bodies) {
        try {
          await _dio.safePost<dynamic>(voicePath(key), data: body);
          return;
        } on ApiException catch (e) {
          lastError = e;
          final msg = e.message.toLowerCase();
          if (e.statusCode == 404 || e.statusCode == 405) rethrow;
          if (e.statusCode == 400 ||
              e.statusCode == 422 ||
              msg.contains('invalid type') ||
              msg.contains('geçersiz alan')) {
            continue;
          }
          rethrow;
        }
      }
      if (lastError != null) throw lastError;
    });
  }

  Future<void> leaveVoiceSession(String roomKey, {String? alternateKey}) async {
    await _withRoomKeyFallback(roomKey, alternateKey, (key) async {
      await _dio.safePost<dynamic>(
        voicePath(key),
        data: const {'action': 'leave'},
      );
    });
  }

  /// Admin kataloğuna arka plan ekle — üretim uçları sırayla denenir.
  Future<void> registerVoiceRoomBackground(String imageUrl) async {
    final url = imageUrl.trim();
    if (url.isEmpty) {
      throw const ApiException('Görsel adresi boş');
    }
    final payloads = [
      {'url': url, 'imageUrl': url},
      {'background': url, 'imageUrl': url},
      {'imageUrl': url},
    ];
    Object? lastError;
    for (final path in [
      '/api/admin/voice-room-backgrounds',
      backgroundsPath(),
    ]) {
      for (final body in payloads) {
        try {
          await _dio.safePost<dynamic>(path, data: body);
          return;
        } on Object catch (e) {
          lastError = e;
        }
      }
    }
    if (lastError != null) throw lastError!;
    throw const ApiException('Arka plan kaydedilemedi');
  }

  Future<List<Map<String, dynamic>>> fetchVoiceUsers(
    String roomKey, {
    String? alternateKey,
  }) async {
    return _withRoomKeyFallback(roomKey, alternateKey, (key) async {
      final res = await _dio.safeGet<dynamic>(voicePath(key));
      final map = _unwrapMap(res.data) ?? asJsonMap(res.data);
      final raw = map['voiceUsers'] ?? map['users'] ?? map['data'];
      if (raw is! List) return const [];
      return raw.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
    });
  }

  Future<void> setTyping(
    String roomKey, {
    required bool isTyping,
    String? alternateKey,
  }) async {
    await _withRoomKeyFallback(roomKey, alternateKey, (key) async {
      await _dio.safePost<dynamic>(
        typingPath(key),
        data: <String, dynamic>{'isTyping': isTyping},
      );
    });
  }

  Future<List<Map<String, dynamic>>> fetchTypingUsers(
    String roomKey, {
    String? alternateKey,
  }) async {
    return _withRoomKeyFallback(roomKey, alternateKey, (key) async {
      final res = await _dio.safeGet<dynamic>(typingPath(key));
      final map = _unwrapMap(res.data) ?? asJsonMap(res.data);
      final raw = map['typingUsers'] ?? map['users'] ?? map['data'];
      if (raw is! List) return const [];
      return raw.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
    });
  }

  Future<({List<VoiceRoomBanEntry> bans, bool canManage})> fetchModeration({
    required String roomKey,
    String? alternateKey,
  }) async {
    return _withRoomKeyFallback(roomKey, alternateKey, (key) async {
      final res = await _dio.safeGet<dynamic>(moderationPath(key));
      final map = _unwrapMap(res.data) ?? asJsonMap(res.data);
      final raw = map['bans'] ?? map['items'];
      final bans = raw is List
          ? raw
              .whereType<Map>()
              .map((e) => VoiceRoomBanEntry.fromJson(
                    Map<String, dynamic>.from(e),
                  ))
              .where((b) => b.userId.isNotEmpty)
              .toList()
          : <VoiceRoomBanEntry>[];
      final canManage = map['canManage'] == true;
      return (bans: bans, canManage: canManage);
    });
  }

  Future<ChatRoomDjState> fetchDj(
    String roomKey, {
    String? alternateKey,
  }) async {
    return _withRoomKeyFallback(roomKey, alternateKey, (key) async {
      final endpoint = djPath(key);
      final res = await _dio.safeGet<dynamic>(endpoint);
      final map = _unwrapMap(res.data) ?? asJsonMap(res.data);
      final np = map['nowPlaying'];
      final npMap = np is Map ? Map<String, dynamic>.from(np) : null;
      VoiceRoomMusicPipelineLog.apiResponse(
        endpoint: endpoint,
        method: 'GET',
        caller: 'fetchDj',
        statusCode: res.statusCode,
        musicUrl: map['musicUrl']?.toString() ?? map['url']?.toString(),
        videoId: VoiceRoomMusicPipelineLog.videoIdFromUrl(
          npMap?['youtubeUrl']?.toString() ??
              npMap?['url']?.toString() ??
              '',
        ),
        playing: map['playing'] == true || map['isPlaying'] == true,
        rawPlayingField: '${map['playing']}/${map['isPlaying']}',
        nowPlayingTitle: npMap?['title']?.toString(),
        nowPlayingYoutube: npMap?['youtubeUrl']?.toString(),
        queueLen: () {
          final q = map['musicQueue'] ?? map['queue'];
          return q is List ? q.length : null;
        }(),
      );
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
      if (!playing) {
        try {
          await _dio.safeDelete<dynamic>(musicPath(key));
        } on ApiException catch (e) {
          if (e.statusCode != 404 && e.statusCode != 405) rethrow;
        }
        return fetchDj(key);
      }
      final res = await _dio.safePost<dynamic>(
        musicPath(key),
        data: <String, dynamic>{
          if (musicUrl != null && musicUrl.isNotEmpty) 'musicUrl': musicUrl,
          'playing': true,
        },
      );
      final map = _unwrapMap(res.data) ?? asJsonMap(res.data);
      return ChatRoomDjState.fromJson(map);
    });
  }

  Future<List<String>> fetchBackgrounds() async {
    final urls = <String>[];
    final seen = <String>{};
    void addUrl(String url) {
      final trimmed = url.trim();
      if (trimmed.isEmpty || !trimmed.startsWith('http')) return;
      if (seen.add(trimmed)) urls.add(trimmed);
    }

    try {
      final res = await _dio.safeGet<dynamic>(
        backgroundsPath(),
        query: {'limit': 128},
      );
      final map = _unwrapMap(res.data) ?? asJsonMap(res.data);
      final raw = map['backgrounds'] ?? map['items'] ?? map['data'];
      for (final url in VoiceRoomBackgroundCatalog.parseApiList(raw)) {
        addUrl(url);
      }
    } catch (_) {}
    if (urls.isNotEmpty) return urls;

    // Backend boş/erişilemezse web ile aynı yerleşik arka planlar fallback.
    for (final url in VoiceRoomBackgroundCatalog.siteDefaults()) {
      addUrl(url);
    }
    return urls;
  }

  /// Yetkili giriş — odadaki herkese ENTRY_ANNOUNCEMENT SSE tetikler.
  Future<void> postEntryAnnouncement({
    required String roomKey,
    String? alternateKey,
    required String userName,
    String? roleSymbol,
    String? entryType,
  }) async {
    await _withRoomKeyFallback(roomKey, alternateKey, (key) async {
      try {
        await _postModeration(
          roomKey: key,
          action: 'entry_announcement',
          message: userName,
        );
        return;
      } on ApiException catch (e) {
        if (e.statusCode != 404 && e.statusCode != 405) rethrow;
      }
      await _postModeration(
        roomKey: key,
        action: 'announce',
        message: '${roleSymbol ?? ''} $userName odaya katıldı${entryType != null && entryType.isNotEmpty ? ' ($entryType)' : ''}'
            .trim(),
        ttl: 8,
        skipPayment: true,
      );
    });
  }

  Future<void> advanceMusicQueue(String roomKey, {String? alternateKey}) async {
    await skipMusicQueue(roomKey: roomKey, alternateKey: alternateKey);
  }

  Future<void> completeMusicQueue(String roomKey, {String? alternateKey}) async {
    await _withRoomKeyFallback(roomKey, alternateKey, (key) async {
      await _dio.safePost<dynamic>(
        '/api/chat/rooms/$key/music-queue/complete',
      );
    });
  }

  Future<void> skipMusicQueue({
    required String roomKey,
    String? alternateKey,
  }) async {
    await _withRoomKeyFallback(roomKey, alternateKey, (key) async {
      await _dio.safePost<dynamic>('/api/chat/rooms/$key/music-queue/advance');
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

  Future<void> reorderMusicQueue({
    required String roomKey,
    String? alternateKey,
    required List<String> orderedItemIds,
  }) async {
    await _withRoomKeyFallback(roomKey, alternateKey, (key) async {
      try {
        await _dio.safePatch<dynamic>(
          '/api/chat/rooms/$key/music-queue',
          data: {'order': orderedItemIds},
        );
      } on ApiException catch (e) {
        if (e.statusCode != 404 && e.statusCode != 405) rethrow;
        await _dio.safePost<dynamic>(
          '/api/chat/rooms/$key/music-queue/reorder',
          data: {'order': orderedItemIds},
        );
      }
    });
  }

  Future<MusicClearResult> clearMusicQueue({
    required String roomKey,
    String? alternateKey,
  }) async {
    return _withRoomKeyFallback(roomKey, alternateKey, (key) async {
      Response<dynamic> res;
      try {
        res = await _dio.safeDelete<dynamic>(musicPath(key));
      } on ApiException catch (e) {
        if (e.statusCode != 404 && e.statusCode != 405) rethrow;
        res = await _dio.safeDelete<dynamic>('/api/chat/rooms/$key/music-queue');
      }
      final map = _unwrapMap(res.data) ?? asJsonMap(res.data);
      return MusicClearResult.fromJson(map.isEmpty ? null : map);
    });
  }

  Future<void> muteRoom({
    required String roomKey,
    String? alternateKey,
    bool mute = true,
  }) async {
    await _withRoomKeyFallback(roomKey, alternateKey, (key) async {
      try {
        await _postModeration(
          roomKey: key,
          action: mute ? 'mute_room' : 'unmute_room',
        );
        return;
      } on ApiException catch (e) {
        if (e.statusCode != 404 && e.statusCode != 405) rethrow;
      }
      await _dio.safePatch<dynamic>(
        '/api/chat/rooms/$key/settings',
        data: {'isMuted': mute},
      );
    });
  }

  Future<void> patchSongRequest({
    required String roomKey,
    String? alternateKey,
    required String requestId,
  }) async {
    await _withRoomKeyFallback(roomKey, alternateKey, (key) async {
      await _dio.safePatch<dynamic>(
        songRequestPath(key),
        data: <String, dynamic>{'requestId': requestId},
      );
    });
  }

  Future<
    ({
      List<MusicQueueItem> queue,
      MusicQueueItem? nowPlaying,
      bool? playing,
      String? musicUrl,
    })
  >
  fetchMusicState(String roomKey, {String? alternateKey}) async {
    return _withRoomKeyFallback(roomKey, alternateKey, (key) async {
      final res = await _dio.safeGet<dynamic>(musicPath(key));
      final parsed = _parseMusicQueueResponse(res.data);
      return (
        queue: parsed.queue,
        nowPlaying: parsed.nowPlaying,
        playing: parsed.playing,
        musicUrl: parsed.musicUrl,
      );
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
        data: <String, dynamic>{
          if (musicEnabled != null) 'musicEnabled': musicEnabled,
          if (musicRequestCost != null) 'musicRequestCost': musicRequestCost,
          if (maxMusicQueue != null) 'maxMusicQueue': maxMusicQueue,
        },
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
            .map(
              (e) =>
                  PopularMusicSuggestion.fromJson(Map<String, dynamic>.from(e)),
            )
            .toList();
      }
    } catch (_) {}
    return fallback;
  }

  Future<void> updateRoomSettings({
    required String roomKey,
    String? alternateKey,
    String? password,
    bool removePassword = false,
  }) async {
    await _withRoomKeyFallback(roomKey, alternateKey, (key) async {
      final data = <String, dynamic>{};
      if (removePassword) {
        data['password'] = null;
        data['entryPassword'] = null;
      } else if (password != null && password.isNotEmpty) {
        data['password'] = password;
        data['entryPassword'] = password;
      }
      if (data.isEmpty) return;
      try {
        await _dio.safePatch<dynamic>(
          '/api/chat/rooms/$key/settings',
          data: data,
        );
      } on ApiException catch (e) {
        if (e.statusCode != 404 && e.statusCode != 405) rethrow;
        await _dio.safePatch<dynamic>(
          '/api/chat/rooms/$key',
          data: data,
        );
      }
    });
  }

  Future<void> setRoomBackground({
    required String roomKey,
    String? alternateKey,
    required String backgroundImage,
  }) async {
    await _withRoomKeyFallback(roomKey, alternateKey, (key) async {
      final settingsPayload = {
        'background': backgroundImage,
        'backgroundImage': backgroundImage,
      };
      final legacyPayload = {'backgroundImage': backgroundImage};
      try {
        // Üretim: kılavuz §9 — PATCH /settings { background }
        await _dio.safePatch<dynamic>(
          '/api/chat/rooms/$key/settings',
          data: settingsPayload,
        );
        return;
      } on ApiException catch (e) {
        if (e.statusCode != 404 && e.statusCode != 405) rethrow;
      }
      try {
        // Yerel mirror / eski uç
        await _dio.safePatch<dynamic>(
          roomBackgroundPath(key),
          data: legacyPayload,
        );
        return;
      } on ApiException catch (e) {
        if (e.statusCode != 404 && e.statusCode != 405) rethrow;
      }
      await _dio.safePatch<dynamic>(
        '/api/chat/rooms/$key',
        data: {...settingsPayload, ...legacyPayload},
      );
    });
  }

  Future<void> requestSpeak(String roomKey, {String? alternateKey}) async {
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

  Future<List<String>> fetchSpeakRequests(
    String roomKey, {
    String? alternateKey,
  }) async {
    List<String> result = [];
    await _withRoomKeyFallback(roomKey, alternateKey, (key) async {
      final res = await _dio.safeGet<dynamic>(
        '/api/chat/rooms/$key/speak-requests',
      );
      final data = res.data;
      if (data is Map) {
        final ids = data['userIds'];
        if (ids is List) result = ids.map((e) => e.toString()).toList();
      }
    });
    return result;
  }

  Future<void> approveSpeakRequest(
    String roomKey,
    String targetUserId, {
    String? alternateKey,
  }) async {
    await _withRoomKeyFallback(roomKey, alternateKey, (key) async {
      await _dio.safePost<dynamic>(
        '/api/chat/rooms/$key/speak-requests/$targetUserId/approve',
      );
    });
  }

  static String banPath(String roomId, String userId) =>
      '/api/chat/rooms/$roomId/bans/$userId';

  static String kickPath(String roomId) => '/api/chat/rooms/$roomId/kick';

  static String mutePath(String roomId) => '/api/chat/rooms/$roomId/mute';

  static String rolePath(String roomId) => '/api/chat/rooms/$roomId/roles';

  Future<Map<String, dynamic>?> _postModeration({
    required String roomKey,
    required String action,
    String? targetUserId,
    String? role,
    String? reason,
    int? duration,
    String? message,
    int? ttl,
    bool skipPayment = false,
    int? jetonCost,
  }) async {
    // Map gönder — jsonEncode string gövdesi üretimde «invalid type» üretir.
    final res = await _dio.safePost<dynamic>(
      moderationPath(roomKey),
      data: <String, dynamic>{
        'action': action,
        if (targetUserId != null && targetUserId.isNotEmpty)
          'targetUserId': targetUserId,
        if (role != null && role.isNotEmpty) ...{
          'role': role,
          'roleSymbol': role,
          'symbol': role,
        },
        if (reason != null && reason.isNotEmpty) 'reason': reason,
        if (message != null && message.trim().isNotEmpty) 'message': message.trim(),
        if (ttl != null && ttl > 0) 'ttl': ttl,
        if (skipPayment) 'skipPayment': true,
        if (jetonCost != null && jetonCost > 0) 'jetonCost': jetonCost,
        if (duration != null) 'duration': duration,
      },
    );
    final map = _unwrapMap(res.data) ?? asJsonMap(res.data);
    return map.isEmpty ? null : map;
  }

  /// Kılavuz §9.3 — oda sahipliğini devret.
  Future<void> transferOwnership({
    required String roomKey,
    String? alternateKey,
    required String newOwnerId,
  }) async {
    final id = newOwnerId.trim();
    if (id.isEmpty) {
      throw const ApiException('Yeni sahip seçilmedi');
    }
    await _withRoomKeyFallback(roomKey, alternateKey, (key) async {
      try {
        await _dio.safePost<dynamic>(
          '/api/chat/rooms/$key/transfer-ownership',
          data: <String, dynamic>{'newOwnerId': id},
        );
        return;
      } on ApiException catch (e) {
        if (e.statusCode != 404 && e.statusCode != 405) rethrow;
      }
      // Yedek: founder rolü (~)
      await assignRole(
        roomKey: key,
        userId: id,
        roleSymbol: '~',
      );
    });
  }

  Future<void> postAnnouncement({
    required String roomKey,
    String? alternateKey,
    required String message,
    int ttl = 15,
    bool skipPayment = false,
    int? jetonCost,
  }) async {
    await _withRoomKeyFallback(roomKey, alternateKey, (key) async {
      await _postModeration(
        roomKey: key,
        action: 'announce',
        message: message,
        ttl: ttl,
        skipPayment: skipPayment,
        jetonCost: jetonCost,
      );
    });
  }

  Future<void> clearChatViaModeration({
    required String roomKey,
    String? alternateKey,
  }) async {
    await _withRoomKeyFallback(roomKey, alternateKey, (key) async {
      try {
        await _postModeration(roomKey: key, action: 'clear_messages');
      } on ApiException catch (e) {
        if (e.statusCode != 404 && e.statusCode != 405) rethrow;
        await _dio.safeDelete<dynamic>(messagesPath(key));
      }
    });
  }

  Future<void> banUser({
    required String roomKey,
    String? alternateKey,
    required String userId,
    String? reason,
  }) async {
    await _withRoomKeyFallback(roomKey, alternateKey, (key) async {
      // Kılavuz §9.3: action "ban"; üretim: ban_user
      for (final action in ['ban', 'ban_user']) {
        try {
          await _postModeration(
            roomKey: key,
            action: action,
            targetUserId: userId,
            reason: reason,
          );
          return;
        } on ApiException catch (e) {
          if (e.statusCode != 404 && e.statusCode != 405) rethrow;
        }
      }
      await _dio.safePost<dynamic>(
        banPath(key, userId),
        data: <String, dynamic>{if (reason != null && reason.isNotEmpty) 'reason': reason},
      );
    });
  }

  Future<void> unbanUser({
    required String roomKey,
    String? alternateKey,
    required String userId,
  }) async {
    await _withRoomKeyFallback(roomKey, alternateKey, (key) async {
      try {
        await _postModeration(
          roomKey: key,
          action: 'unban_user',
          targetUserId: userId,
        );
        return;
      } on ApiException catch (e) {
        if (e.statusCode != 404 && e.statusCode != 405) rethrow;
      }
      await _dio.safeDelete<dynamic>(banPath(key, userId));
    });
  }

  Future<void> unmuteUser({
    required String roomKey,
    String? alternateKey,
    required String userId,
  }) async {
    await _withRoomKeyFallback(roomKey, alternateKey, (key) async {
      try {
        await _postModeration(
          roomKey: key,
          action: 'unmute_user',
          targetUserId: userId,
        );
        return;
      } on ApiException catch (e) {
        if (e.statusCode != 404 && e.statusCode != 405) rethrow;
      }
      await _dio.safePost<dynamic>(
        mutePath(key),
        data: <String, dynamic>{'userId': userId, 'unmute': true},
      );
    });
  }

  Future<ModerationKickResult> kickUser({
    required String roomKey,
    String? alternateKey,
    required String userId,
    String? reason,
  }) async {
    return _withRoomKeyFallback(roomKey, alternateKey, (key) async {
      try {
        final map = await _postModeration(
          roomKey: key,
          action: 'kick_user',
          targetUserId: userId,
          reason: reason,
        );
        return ModerationKickResult.fromJson(map);
      } on ApiException catch (e) {
        if (e.statusCode != 404 && e.statusCode != 405) rethrow;
      }
      await _dio.safePost<dynamic>(
        kickPath(key),
        data: <String, dynamic>{
          'userId': userId,
          if (reason != null && reason.isNotEmpty) 'reason': reason,
        },
      );
      return const ModerationKickResult();
    });
  }

  Future<void> muteUser({
    required String roomKey,
    String? alternateKey,
    required String userId,
    int minutes = 30,
    String? reason,
  }) async {
    await _withRoomKeyFallback(roomKey, alternateKey, (key) async {
      // Kılavuz §9.3: action "mute"; üretim: mute_user
      for (final action in ['mute', 'mute_user']) {
        try {
          await _postModeration(
            roomKey: key,
            action: action,
            targetUserId: userId,
            reason: reason,
            duration: minutes,
          );
          return;
        } on ApiException catch (e) {
          if (e.statusCode != 404 && e.statusCode != 405) rethrow;
        }
      }
      await _dio.safePost<dynamic>(
        mutePath(key),
        data: <String, dynamic>{
          'userId': userId,
          'minutes': minutes,
          'durationMinutes': minutes,
          if (reason != null && reason.isNotEmpty) 'reason': reason,
        },
      );
    });
  }

  Future<void> assignRole({
    required String roomKey,
    String? alternateKey,
    required String userId,
    required String roleSymbol,
  }) async {
    await _withRoomKeyFallback(roomKey, alternateKey, (key) async {
      final actions = <String>[
        'set_role',
        if (roleSymbol == '+') 'give_voice',
        if (roleSymbol == '@') 'give_op',
        if (roleSymbol == '&') 'give_sop',
        if (roleSymbol == '~') 'give_founder',
      ];
      ApiException? lastError;
      for (final action in actions) {
        try {
          await _postModeration(
            roomKey: key,
            action: action,
            targetUserId: userId,
            role: roleSymbol,
          );
          return;
        } on ApiException catch (e) {
          lastError = e;
          if (e.statusCode == 404 || e.statusCode == 405) continue;
          if (e.statusCode != null && e.statusCode! >= 500) continue;
          rethrow;
        }
      }
      try {
        await _dio.safePost<dynamic>(
          rolePath(key),
          data: <String, dynamic>{
            'userId': userId,
            'role': roleSymbol,
            'symbol': roleSymbol,
            'roleSymbol': roleSymbol,
          },
        );
        return;
      } on ApiException catch (e) {
        if (e.statusCode != 404 && e.statusCode != 405) {
          if (lastError != null) throw lastError!;
          rethrow;
        }
      }
      if (lastError != null) throw lastError!;
    });
  }

  List<YoutubeSearchHit> _parseYoutubeHits(dynamic body) {
    dynamic raw;
    if (body is Map) {
      raw = body['items'] ?? body['videos'] ?? body['results'] ?? body['data'];
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
      final url =
          m['url']?.toString() ?? 'https://www.youtube.com/watch?v=$vid';
      out.add(
        YoutubeSearchHit(
          videoId: vid,
          title: m['title']?.toString() ?? 'Video',
          url: url,
          thumbUrl: m['thumbUrl']?.toString() ?? m['thumbnail']?.toString(),
          uploader:
              m['uploader']?.toString() ??
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
    if (raw is Duration) {
      final sec = raw.inSeconds;
      if (sec <= 0) return null;
      final m = sec ~/ 60;
      final s = sec % 60;
      return '$m:${s.toString().padLeft(2, '0')}';
    }
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
    final started = DateTime.now();
    VoiceRoomDebugLog.log('music.search.start', {'q': q});

    final directId = _extractYoutubeId(q);
    if (directId != null) {
      final hit = YoutubeSearchHit(
        videoId: directId,
        title: 'YouTube bağlantısı',
        url: 'https://www.youtube.com/watch?v=$directId',
        thumbUrl: 'https://i.ytimg.com/vi/$directId/hqdefault.jpg',
      );
      VoiceRoomDebugLog.log('music.search.direct_id', {
        'ms': DateTime.now().difference(started).inMilliseconds,
      });
      return [hit];
    }

    final cached = _searchCache.get(q);
    if (cached != null) {
      VoiceRoomDebugLog.log('music.search.cache_hit', {
        'q': q,
        'count': cached.length,
        'ms': DateTime.now().difference(started).inMilliseconds,
      });
      return cached;
    }

    Object? backendError;
    try {
      final hits = await _searchMusicViaBackend(q);
      if (hits.isNotEmpty) {
        _searchCache.put(q, hits);
        VoiceRoomDebugLog.log('music.search.ok', {
          'q': q,
          'count': hits.length,
          'ms': DateTime.now().difference(started).inMilliseconds,
        });
        return hits;
      }
    } on ApiException catch (e) {
      backendError = e;
      VoiceRoomDebugLog.log('music.search.fail', {
        'q': q,
        'status': e.statusCode,
        'ms': DateTime.now().difference(started).inMilliseconds,
      });
      if (e.statusCode == 401) rethrow;
      if (e.statusCode == 503) {
        throw const ApiException(
          'Müzik araması sunucuda yapılandırılmamış. Lütfen daha sonra tekrar deneyin.',
        );
      }
    } catch (e) {
      backendError = e;
      VoiceRoomDebugLog.log('music.search.fail', {
        'q': q,
        'error': '$e',
        'ms': DateTime.now().difference(started).inMilliseconds,
      });
    }

    final catalogHits = await _searchYoutubeFromPopularCatalog(q);
    if (catalogHits.isNotEmpty) {
      _searchCache.put(q, catalogHits);
      VoiceRoomDebugLog.log('music.search.catalog_ok', {
        'q': q,
        'count': catalogHits.length,
        'ms': DateTime.now().difference(started).inMilliseconds,
      });
      return catalogHits;
    }

    final clientHits = await _searchYoutubeWithClient(q);
    if (clientHits.isNotEmpty) {
      _searchCache.put(q, clientHits);
      VoiceRoomDebugLog.log('music.search.client_ok', {
        'q': q,
        'count': clientHits.length,
        'ms': DateTime.now().difference(started).inMilliseconds,
      });
      return clientHits;
    }

    VoiceRoomDebugLog.log('music.search.empty', {
      'q': q,
      if (backendError != null) 'backendError': '$backendError',
      'ms': DateTime.now().difference(started).inMilliseconds,
    });
    throw const ApiException('Şarkı bulunamadı. Farklı bir arama deneyin.');
  }

  Future<List<YoutubeSearchHit>> _searchMusicViaBackend(String q) async {
    try {
      final res = await _dio
          .get<dynamic>(
            ApiEndpoints.youtubeSearch,
            queryParameters: {'q': q, 'query': q},
          )
          .timeout(const Duration(seconds: 15));
      final hits = _parseYoutubeHits(res.data);
      if (hits.isNotEmpty) return hits;
    } on TimeoutException {
      throw const ApiException('Arama zaman aşımına uğradı. Tekrar deneyin.');
    } on DioException catch (e) {
      final status = e.response?.statusCode;
      if (status == 401 || status == 503) {
        throw _mapDioForYoutube(e);
      }
    }

    try {
      final res = await _dio
          .get<dynamic>(musicSearchPath(), queryParameters: {'q': q})
          .timeout(const Duration(seconds: 15));
      final data = res.data;
      if (data is String &&
          (data.contains('<!DOCTYPE') || data.contains('<html'))) {
        throw const ApiException('Müzik araması geçersiz yanıt döndü.');
      }
      return _parseYoutubeHits(data);
    } on DioException catch (e) {
      final status = e.response?.statusCode;
      if (status == 404) return const [];
      throw _mapDioForYoutube(e);
    }
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

  Future<List<YoutubeSearchHit>> _searchYoutubeFromPopularCatalog(
    String q,
  ) async {
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

  Future<List<YoutubeSearchHit>> _searchYoutubeWithClient(String q) async {
    try {
      final videos = await _youtube.search
          .getVideos(q)
          .timeout(const Duration(seconds: 18));
      final hits = <YoutubeSearchHit>[];
      for (final video in videos.take(10)) {
        if (video.isLive) continue;
        final id = video.id.value;
        if (id.length < 6) continue;
        hits.add(
          YoutubeSearchHit(
            videoId: id,
            title: video.title,
            url: video.url,
            thumbUrl: video.thumbnails.mediumResUrl,
            uploader: video.author,
            duration: _formatDuration(video.duration),
          ),
        );
      }
      return hits;
    } catch (e) {
      VoiceRoomDebugLog.log('music.search.client_fail', {
        'q': q,
        'error': '$e',
      });
      return const [];
    }
  }

  /// Üretimde komut işlenmezse sohbeti temizlemek için dene.
  Future<void> tryClearRoomMessages({
    required String roomKey,
    String? alternateKey,
  }) async {
    try {
      await clearChatViaModeration(roomKey: roomKey, alternateKey: alternateKey);
    } catch (_) {}
  }

  Future<
    ({
      List<MusicQueueItem> queue,
      int cost,
      int videoRequestCost,
      int maxMusicQueue,
      bool musicEnabled,
      MusicQueueItem? nowPlaying,
      bool? playing,
      bool? canRequestMusic,
      String? musicUrl,
    })
  >
  fetchMusicQueue(String roomKey, {String? alternateKey}) async {
    return _withRoomKeyFallback(roomKey, alternateKey, (key) async {
      Response<dynamic>? res;
      for (final path in [
        musicPath(key),
        songRequestPath(key),
        '/api/chat/rooms/$key/music-queue',
        djPath(key),
      ]) {
        try {
          res = await _dio.safeGet<dynamic>(path);
          final parsed = _parseMusicQueueResponse(res.data);
          VoiceRoomMusicPipelineLog.apiResponse(
            endpoint: path,
            method: 'GET',
            caller: 'fetchMusicQueue',
            statusCode: res.statusCode,
            musicUrl: parsed.musicUrl,
            videoId: VoiceRoomMusicPipelineLog.videoIdFromItem(
              parsed.nowPlaying,
            ),
            playing: parsed.playing,
            nowPlayingTitle: parsed.nowPlaying?.title,
            nowPlayingYoutube: parsed.nowPlaying?.youtubeUrl,
            queueLen: parsed.queue.length,
          );
          if (parsed.queue.isNotEmpty ||
              parsed.nowPlaying != null ||
              parsed.musicUrl != null ||
              parsed.musicEnabled == false) {
            return parsed;
          }
          VoiceRoomMusicPipelineLog.nullMusicUrl(
            reason: 'endpoint_empty_payload',
            endpoint: path,
            caller: 'fetchMusicQueue',
            playing: parsed.playing,
            queueLen: parsed.queue.length,
            detail: 'queue+nowPlaying+musicUrl all empty',
          );
          continue;
        } on Object catch (e) {
          VoiceRoomMusicPipelineLog.nullMusicUrl(
            reason: 'endpoint_request_failed',
            endpoint: path,
            caller: 'fetchMusicQueue',
            detail: '$e',
          );
          continue;
        }
      }
      if (res == null) {
        throw const ApiException('Müzik kuyruğu alınamadı');
      }
      return _parseMusicQueueResponse(res.data);
    });
  }

    ({
      List<MusicQueueItem> queue,
      int cost,
      int videoRequestCost,
      int maxMusicQueue,
      bool musicEnabled,
      MusicQueueItem? nowPlaying,
      bool? playing,
      bool? canRequestMusic,
      String? musicUrl,
    })
  _parseMusicQueueResponse(dynamic body) {
    final map = _unwrapMap(body) ?? asJsonMap(body);
    final raw = pick(map, [
      'queue',
      'musicQueue',
      'items',
      'songs',
      'requests',
    ]);
    final queue = <MusicQueueItem>[];
    if (raw is List) {
      for (final e in raw) {
        if (e is Map) {
          queue.add(MusicQueueItem.fromJson(Map<String, dynamic>.from(e)));
        }
      }
    }
    MusicQueueItem? nowPlaying;
    final np = pick(map, [
      'nowPlaying',
      'currentSong',
      'currentTrack',
      'playingItem',
      'activeItem',
    ]);
    if (np is Map) {
      nowPlaying = MusicQueueItem.fromJson(Map<String, dynamic>.from(np));
    } else if ((map['playing'] == true || map['isPlaying'] == true) &&
        queue.isNotEmpty) {
      nowPlaying = queue.first;
    }
    final musicUrlRaw = pick(map, [
      'musicUrl',
      'streamUrl',
      'audioUrl',
      'url',
    ])?.toString();
    final playingRaw = pick(map, ['playing', 'isPlaying']);
    final canRequestRaw = pick(map, ['canRequestMusic', 'canRequest']);
    final costs = _parseRequestCosts(map);
    return (
      queue: queue,
      cost: costs.audio,
      videoRequestCost: costs.video,
      maxMusicQueue:
          asInt(pick(map, ['maxMusicQueue', 'maxQueueLength', 'limit'])) == 0
          ? 20
          : asInt(pick(map, ['maxMusicQueue', 'maxQueueLength', 'limit'])),
      musicEnabled: pick(map, ['musicEnabled', 'enabled']) != false,
      nowPlaying: nowPlaying,
      playing: playingRaw == null ? null : playingRaw == true,
      canRequestMusic: canRequestRaw == null ? null : canRequestRaw == true,
      musicUrl: musicUrlRaw != null && musicUrlRaw.isNotEmpty
          ? musicUrlRaw
          : null,
    );
  }

  ({int audio, int video}) _parseRequestCosts(Map<String, dynamic> map) {
    final raw = map['requestCosts'];
    if (raw is Map) {
      final audio = asInt(raw['audio']);
      final video = asInt(raw['video']);
      if (audio > 0 && video > 0) {
        return (audio: audio, video: video);
      }
      if (audio > 0) {
        return (audio: audio, video: video > 0 ? video : audio * 2);
      }
      if (video > 0) {
        return (audio: 10, video: video);
      }
    }
    final audioCost = asInt(pick(map, ['cost', 'musicRequestCost', 'requestCost']));
    final resolvedAudio = audioCost == 0 ? 10 : audioCost;
    final videoCost = asInt(
      pick(map, ['videoRequestCost', 'videoMusicRequestCost', 'videoCost']),
    );
    return (
      audio: resolvedAudio,
      video: videoCost > 0 ? videoCost : resolvedAudio * 2,
    );
  }

  Future<
    ({
      MusicQueueItem? item,
      List<MusicQueueItem> queue,
      int? newBalance,
      int? queuePosition,
      String? musicUrl,
      bool playing,
    })
  >
  requestMusic({
    required String roomKey,
    String? alternateKey,
    required String title,
    required String youtubeUrl,
    String? thumbUrl,
    String? videoId,
    String? duration,
    String? giftTo,
    String? dedication,
    String? note,
    bool priority = true,
    bool skipPayment = false,
    bool djMusicControl = false,
    bool withVideo = false,
  }) async {
    return _withRoomKeyFallback(roomKey, alternateKey, (key) async {
      final vid = videoId?.trim().isNotEmpty == true
          ? videoId!.trim()
          : _extractYoutubeId(youtubeUrl);
      final durationLabel = _normalizeDurationLabel(duration);
      final dedicationText =
          dedication?.trim().isNotEmpty == true
              ? dedication!.trim()
              : giftTo?.trim();
      VoiceRoomDebugLog.log('music.queue.add', {
        'room': key,
        'title': title,
        'priority': priority,
        'skipPayment': skipPayment,
        'djMusicControl': djMusicControl,
      });
      final songRequestBody = <String, dynamic>{
        if (vid != null && vid.isNotEmpty) 'videoId': vid,
        'title': title,
        if (durationLabel != null && durationLabel.isNotEmpty)
          'duration': durationLabel,
        'requestType': withVideo ? 'video' : 'audio',
        if (withVideo) 'withVideo': true,
        if (withVideo) 'videoMode': 'video',
        if (!withVideo) 'videoMode': 'audio',
        if (dedicationText != null && dedicationText.isNotEmpty)
          'dedication': dedicationText,
        if (note != null && note.trim().isNotEmpty) 'note': note.trim(),
        if (skipPayment) 'skipPayment': true,
        if (priority) 'priority': true,
      };
      final legacyBody = <String, dynamic>{
        'title': title,
        'youtubeUrl': youtubeUrl,
        if (vid != null && vid.isNotEmpty) 'videoId': vid,
        if (thumbUrl != null && thumbUrl.isNotEmpty) 'thumbUrl': thumbUrl,
        if (dedicationText != null && dedicationText.isNotEmpty)
          'dedication': dedicationText,
        if (giftTo != null && giftTo.trim().isNotEmpty) 'giftTo': giftTo.trim(),
        if (note != null && note.trim().isNotEmpty) 'note': note.trim(),
        if (priority) 'priority': true,
        if (skipPayment) 'skipPayment': true,
        if (durationLabel != null && durationLabel.isNotEmpty)
          'duration': durationLabel,
      };
      final djMusicBody = <String, dynamic>{
        'title': title,
        if (vid != null && vid.isNotEmpty) 'videoId': vid,
        if (durationLabel != null && durationLabel.isNotEmpty)
          'duration': durationLabel,
      };
      Response<dynamic> res;
      var usedEndpoint = songRequestPath(key);
      if (djMusicControl) {
        usedEndpoint = musicPath(key);
        try {
          res = await _dio.safePost<dynamic>(
            usedEndpoint,
            data: djMusicBody,
          );
        } on Object {
          usedEndpoint = songRequestPath(key);
          res = await _dio.safePost<dynamic>(
            usedEndpoint,
            data: songRequestBody,
          );
        }
      } else {
        try {
          res = await _dio.safePost<dynamic>(
            usedEndpoint,
            data: songRequestBody,
          );
        } on Object {
          usedEndpoint = '/api/chat/rooms/$key/music-queue';
          try {
            res = await _dio.safePost<dynamic>(
              usedEndpoint,
              data: legacyBody,
            );
          } on Object {
            usedEndpoint = musicPath(key);
            res = await _dio.safePost<dynamic>(
              usedEndpoint,
              data: djMusicBody,
            );
          }
        }
      }
      final map = _unwrapMap(res.data) ?? asJsonMap(res.data);
      MusicQueueItem? item;
      final itemRaw = pick(map, ['item', 'request', 'song', 'track']);
      if (itemRaw is Map) {
        item = MusicQueueItem.fromJson(Map<String, dynamic>.from(itemRaw));
      }
      final queueRaw = pick(map, [
        'queue',
        'musicQueue',
        'items',
        'songs',
        'requests',
      ]);
      final queue = <MusicQueueItem>[];
      if (queueRaw is List) {
        for (final e in queueRaw) {
          if (e is Map) {
            queue.add(MusicQueueItem.fromJson(Map<String, dynamic>.from(e)));
          }
        }
      }
      final balance = asInt(
        pick(map, ['newBalance', 'coinBalance', 'balance']),
      );
      final position = asInt(pick(map, ['queuePosition', 'position', 'rank']));
      final musicUrlRaw = pick(map, [
        'musicUrl',
        'streamUrl',
        'audioUrl',
        'url',
      ])?.toString();
      final playing = map['playing'] == true || map['isPlaying'] == true;
      final fallbackQueue = queue.isEmpty
          ? await fetchMusicQueue(key, alternateKey: null)
          : null;
      VoiceRoomDebugLog.log('music.queue.add.ok', {
        'room': key,
        'playing': playing,
        'queueLen': queue.isNotEmpty
            ? queue.length
            : fallbackQueue?.queue.length,
        'position': position == 0 ? null : position,
        'hasUrl': musicUrlRaw != null && musicUrlRaw.isNotEmpty,
      });
      VoiceRoomMusicPipelineLog.apiResponse(
        endpoint: usedEndpoint,
        method: 'POST',
        caller: 'requestMusic',
        statusCode: res.statusCode,
        musicUrl: musicUrlRaw,
        videoId: vid,
        playing: playing,
        nowPlayingTitle: item?.title,
        nowPlayingYoutube: item?.youtubeUrl,
        queueLen: queue.isNotEmpty
            ? queue.length
            : fallbackQueue?.queue.length,
      );
      if (musicUrlRaw == null || musicUrlRaw.isEmpty) {
        VoiceRoomMusicPipelineLog.nullMusicUrl(
          reason: 'song_request_no_stream_resolved',
          endpoint: usedEndpoint,
          caller: 'requestMusic',
          playing: playing,
          queueLen: queue.length,
          hasNowPlaying: item != null,
          detail:
              'Sunucu kuyruğa ekledi ama musicUrl null — web tryStartMusicFromQueue stream çözemedi olabilir',
        );
      }
      return (
        item: item,
        queue: queue.isNotEmpty ? queue : (fallbackQueue?.queue ?? const []),
        newBalance: balance == 0 ? null : balance,
        queuePosition: position == 0 ? null : position,
        musicUrl: musicUrlRaw != null && musicUrlRaw.isNotEmpty
            ? musicUrlRaw
            : fallbackQueue?.musicUrl,
        playing: playing || fallbackQueue?.playing == true,
      );
    });
  }

  Future<
    ({
      MusicQueueItem? item,
      List<MusicQueueItem> queue,
      int? newBalance,
      int? queuePosition,
      String? musicUrl,
      bool playing,
    })
  >
  requestMusicByQuery({
    required String roomKey,
    String? alternateKey,
    required String query,
  }) async {
    return _withRoomKeyFallback(roomKey, alternateKey, (key) async {
      final res = await _dio.safePost<dynamic>(
        '/api/chat/rooms/$key/music-request-by-query',
        data: <String, dynamic>{'query': query.trim()},
      );
      final map = _unwrapMap(res.data) ?? asJsonMap(res.data);
      MusicQueueItem? item;
      final itemRaw = pick(map, ['item', 'request', 'song', 'track']);
      if (itemRaw is Map) {
        item = MusicQueueItem.fromJson(Map<String, dynamic>.from(itemRaw));
      }
      final queueRaw = pick(map, ['queue', 'musicQueue', 'items']);
      final queue = <MusicQueueItem>[];
      if (queueRaw is List) {
        for (final e in queueRaw) {
          if (e is Map) {
            queue.add(MusicQueueItem.fromJson(Map<String, dynamic>.from(e)));
          }
        }
      }
      final balance = asInt(
        pick(map, ['newBalance', 'coinBalance', 'balance']),
      );
      final position = asInt(pick(map, ['queuePosition', 'position', 'rank']));
      final musicUrlRaw = pick(map, ['musicUrl', 'streamUrl', 'audioUrl'])
          ?.toString();
      final playing = map['playing'] == true || map['isPlaying'] == true;
      return (
        item: item,
        queue: queue,
        newBalance: balance == 0 ? null : balance,
        queuePosition: position == 0 ? null : position,
        musicUrl: musicUrlRaw,
        playing: playing,
      );
    });
  }

  /// Yetkili rol (owner/admin/mod/dj) — önce `join-seat`, sonra `seats` / presence.
  Future<void> joinSeat({
    required String roomKey,
    String? alternateKey,
    int? seatIndex,
    String? userId,
  }) async {
    final body = <String, dynamic>{
      if (seatIndex != null) 'seatIndex': seatIndex,
      if (userId != null && userId.isNotEmpty) 'userId': userId,
    };
    await _withRoomKeyFallback(roomKey, alternateKey, (key) async {
      for (final path in [
        ApiEndpoints.chatRoomJoinSeat(key),
        seatsPath(key),
      ]) {
        try {
          await _dio.safePost<dynamic>(path, data: body);
          return;
        } on ApiException catch (e) {
          if (e.statusCode == 404 || e.statusCode == 405) continue;
          rethrow;
        }
      }
      try {
        await _dio.safePatch<dynamic>(seatsPath(key), data: body);
        return;
      } on ApiException catch (e) {
        if (e.statusCode != 404 && e.statusCode != 405) rethrow;
      }
      await _dio.safePost<dynamic>(presencePath(key), data: body);
    });
  }

  Future<void> clearSeat({
    required String roomKey,
    String? alternateKey,
    String? userId,
  }) async {
    final body = <String, dynamic>{
      'seatIndex': -1,
      if (userId != null && userId.isNotEmpty) 'userId': userId,
    };
    await _withRoomKeyFallback(roomKey, alternateKey, (key) async {
      try {
        await _dio.safePatch<dynamic>(seatsPath(key), data: body);
        return;
      } on ApiException catch (e) {
        if (e.statusCode != 405 && e.statusCode != 404) rethrow;
      }
      try {
        await _dio.safePost<dynamic>(seatsPath(key), data: body);
        return;
      } on ApiException catch (e) {
        if (e.statusCode != 405 && e.statusCode != 404) rethrow;
      }
      await _dio.safePost<dynamic>(presencePath(key), data: body);
    });
  }

  Future<void> assignSeat({
    required String roomKey,
    String? alternateKey,
    required int seatIndex,
    String? userId,
  }) async {
    await _withRoomKeyFallback(roomKey, alternateKey, (key) async {
      final targetId = userId?.trim();
      final isOther = targetId != null && targetId.isNotEmpty;

      Map<String, dynamic> seatPayload(String action, int index) => {
            'action': action,
            'seatIndex': index,
            if (isOther) ...{
              'userId': targetId,
              'targetUserId': targetId,
            },
          };

      final payloads = <Map<String, dynamic>>[
        if (isOther) ...[
          seatPayload('force', seatIndex),
          seatPayload('take', seatIndex),
          seatPayload('sit', seatIndex),
        ] else ...[
          seatPayload('take', seatIndex),
          seatPayload('sit', seatIndex),
          if (seatIndex > 0) seatPayload('take', seatIndex - 1),
        ],
      ];

      ApiException? lastError;
      for (final payload in payloads) {
        for (final send in [_dio.safePost<dynamic>, _dio.safePatch<dynamic>]) {
          try {
            await send(seatsPath(key), data: payload);
            return;
          } on ApiException catch (e) {
            lastError = e;
            if (e.statusCode == 404 ||
                e.statusCode == 405 ||
                e.statusCode == 400 ||
                e.statusCode == 422) {
              continue;
            }
            rethrow;
          }
        }
      }

      final presenceBody = <String, dynamic>{
        'action': 'join',
        'seatIndex': seatIndex,
        if (isOther) 'userId': targetId,
      };
      try {
        await _dio.safePost<dynamic>(presencePath(key), data: presenceBody);
        return;
      } on ApiException catch (e) {
        lastError = e;
      }
      if (lastError != null) throw lastError;
    });
  }

  List<String> _parseDjUserIdsResponse(dynamic body) {
    final map = _unwrapMap(body) ?? asJsonMap(body);
    final raw = map['djUserIds'];
    if (raw is List) {
      return raw.map((e) => e.toString()).where((s) => s.isNotEmpty).toList();
    }
    if (raw is String && raw.trim().startsWith('[')) {
      try {
        final decoded = jsonDecode(raw);
        if (decoded is List) {
          return decoded
              .map((e) => e.toString())
              .where((s) => s.isNotEmpty)
              .toList();
        }
      } catch (_) {}
    }
    return const [];
  }

  Future<List<String>> _fetchDjUserIdsAfterMutation(String roomKey) async {
    await Future<void>.delayed(const Duration(milliseconds: 700));
    final dj = await fetchDj(roomKey);
    return dj.djUsers.map((u) => u.id).where((id) => id.isNotEmpty).toList();
  }

  Future<List<String>> _mutateDjViaChatCommand({
    required String roomKey,
    required String targetUserId,
    required String? targetLabel,
  }) async {
    final label = targetLabel?.trim().replaceFirst(RegExp(r'^@'), '');
    if (label == null || label.isEmpty) {
      throw const ApiException(
        'DJ işlemi için kullanıcı adı gerekli (üretim: !dj komutu).',
      );
    }
    await sendMessage(roomKey: roomKey, content: '!dj @$label');
    final ids = await _fetchDjUserIdsAfterMutation(roomKey);
    if (ids.contains(targetUserId) || ids.isNotEmpty) return ids;
    throw const ApiException('DJ güncellenemedi. Tekrar deneyin.');
  }

  Future<List<String>> _postDjAction({
    required String roomKey,
    required String action,
    String? userId,
  }) async {
    // Kılavuz §9.3: assign/remove + targetUserId — Map body (string değil).
    final res = await _dio.safePost<dynamic>(
      djPath(roomKey),
      data: <String, dynamic>{
        'action': action,
        if (userId != null && userId.isNotEmpty) ...{
          'targetUserId': userId,
          'userId': userId,
        },
      },
    );
    final ids = _parseDjUserIdsResponse(res.data);
    if (ids.isNotEmpty) return ids;
    return _fetchDjUserIdsAfterMutation(roomKey);
  }

  Future<List<String>> setActiveDj({
    required String roomKey,
    String? alternateKey,
    String? userId,
  }) async {
    return _withRoomKeyFallback(roomKey, alternateKey, (key) async {
      return _postDjAction(
        roomKey: key,
        action: 'set_active_dj',
        userId: userId,
      );
    });
  }

  Future<List<String>> addRoomDj({
    required String roomKey,
    String? alternateKey,
    required String targetUserId,
    String? targetLabel,
  }) async {
    return _withRoomKeyFallback(roomKey, alternateKey, (key) async {
      ApiException? restError;
      try {
        // Kılavuz §9.3: assign + targetUserId
        return await _postDjAction(
          roomKey: key,
          action: 'assign',
          userId: targetUserId,
        );
      } on ApiException catch (_) {}
      try {
        return await _postDjAction(
          roomKey: key,
          action: 'add_dj',
          userId: targetUserId,
        );
      } on ApiException catch (e) {
        restError = e;
        if (e.statusCode != 404 && e.statusCode != 405) rethrow;
      }
      try {
        final res = await _dio.safePost<dynamic>(
          '/api/chat/rooms/$key/dj/$targetUserId',
        );
        final ids = _parseDjUserIdsResponse(res.data);
        if (ids.isNotEmpty) return ids;
      } on ApiException catch (e) {
        restError = e;
        if (e.statusCode != 404 && e.statusCode != 405) rethrow;
      }
      try {
        return await _mutateDjViaChatCommand(
          roomKey: key,
          targetUserId: targetUserId,
          targetLabel: targetLabel,
        );
      } catch (_) {
        throw restError;
      }
    });
  }

  Future<List<String>> removeRoomDj({
    required String roomKey,
    String? alternateKey,
    required String targetUserId,
    String? targetLabel,
  }) async {
    return _withRoomKeyFallback(roomKey, alternateKey, (key) async {
      ApiException? restError;
      try {
        // Kılavuz §9.3: remove + targetUserId
        return await _postDjAction(
          roomKey: key,
          action: 'remove',
          userId: targetUserId,
        );
      } on ApiException catch (_) {}
      try {
        return await _postDjAction(
          roomKey: key,
          action: 'remove_dj',
          userId: targetUserId,
        );
      } on ApiException catch (e) {
        restError = e;
        if (e.statusCode != 404 && e.statusCode != 405) rethrow;
      }
      try {
        final res = await _dio.safeDelete<dynamic>(
          '/api/chat/rooms/$key/dj/$targetUserId',
        );
        final ids = _parseDjUserIdsResponse(res.data);
        if (ids.isNotEmpty || res.statusCode == 200) return ids;
      } on ApiException catch (e) {
        restError = e;
        if (e.statusCode != 404 && e.statusCode != 405) rethrow;
      }
      try {
        return await _mutateDjViaChatCommand(
          roomKey: key,
          targetUserId: targetUserId,
          targetLabel: targetLabel,
        );
      } catch (_) {
        throw restError;
      }
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
        data: <String, dynamic>{'word': word},
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

  String? _normalizeDurationLabel(String? duration) {
    final raw = duration?.trim();
    if (raw == null || raw.isEmpty) return null;
    if (raw.contains(':')) return raw;
    final sec = int.tryParse(raw);
    if (sec == null || sec <= 0) return raw;
    final m = sec ~/ 60;
    final s = sec % 60;
    return '$m:${s.toString().padLeft(2, '0')}';
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
    String? nickname,
    List<String> mentionedUserIds = const [],
  }) async {
    try {
      final liveMsg = await _liveField.messages.sendMessage(
        roomId: roomKey,
        roomType: 'voice',
        content: content,
      );
      if (liveMsg.id.isNotEmpty || liveMsg.content.isNotEmpty) {
        return ChatRoomMessage(
          id: liveMsg.id.isNotEmpty
              ? liveMsg.id
              : 'live-${DateTime.now().millisecondsSinceEpoch}',
          content: liveMsg.content,
          createdAt: liveMsg.createdAt ?? DateTime.now(),
          user: ChatRoomUserRef(
            id: liveMsg.userId ?? '',
            name: liveMsg.userName ?? nickname ?? 'Kullanıcı',
            image: liveMsg.userImage,
            chatRole: liveMsg.chatRole,
            roleSymbol: liveMsg.roleSymbol,
            nickname: nickname,
          ),
        );
      }
    } on ApiException catch (e) {
      if (e.statusCode != 404 && e.statusCode != 405) rethrow;
    } catch (_) {}

    return _withRoomKeyFallback(roomKey, alternateKey, (key) async {
      final nick = nickname?.trim();
      final res = await _dio
          .safePost<dynamic>(
            messagesPath(key),
            data: <String, dynamic>{
              'content': content,
              if (nick != null && nick.isNotEmpty) 'nickname': nick,
              if (mentionedUserIds.isNotEmpty) ...{
                'mentionedUserIds': mentionedUserIds,
                'mentionUserIds': mentionedUserIds,
                'mentions': mentionedUserIds,
              },
            },
          )
          .timeout(const Duration(seconds: 25));
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

  /// Faz 11 — @ etiket bildirimi (yerel API / yedek uç).
  Future<void> notifyRoomMentions({
    required String roomKey,
    String? alternateKey,
    required List<String> mentionedUserIds,
    required String preview,
  }) async {
    if (mentionedUserIds.isEmpty) return;
    await _withRoomKeyFallback(roomKey, alternateKey, (key) async {
      try {
        await _dio.safePost<dynamic>(
          '/api/chat/rooms/$key/mentions',
          data: <String, dynamic>{
            'mentionedUserIds': mentionedUserIds,
            'preview': preview,
          },
        );
      } on ApiException catch (e) {
        if (e.statusCode == 404 || e.statusCode == 405) return;
        rethrow;
      }
    });
  }
}
