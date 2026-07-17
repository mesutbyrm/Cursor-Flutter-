import 'dart:convert';

import 'package:dio/dio.dart';

import '../core/api_response.dart';
import '../core/network/api_endpoints.dart';
import '../core/network/api_exception.dart';
import '../core/network/dio_provider.dart';
import '../core/sse_client.dart';
import '../core/util/json_util.dart';
import '../features/agora/domain/entities/agora_credentials.dart';
import '../features/trtc/domain/entities/trtc_credentials.dart';
import 'models/chat_music_hit.dart';
import 'models/chat_presence.dart';
import 'models/chat_room_summary.dart';
import 'models/chat_service_message.dart';

/// Canlifal sohbet / sesli oda API — kılavuz §9.3 `ChatRoomRepository`.
///
/// Base URL: `https://canlifal.com` · Auth: JWT Bearer
class ChatService {
  ChatService({
    required Dio Function() resolveAuthedDio,
    SseClient? sseClient,
  })  : _resolveAuthedDio = resolveAuthedDio,
        _sseClient = sseClient;

  final Dio Function() _resolveAuthedDio;
  final SseClient? _sseClient;

  Dio get _dio => _resolveAuthedDio();

  // ── 1. Temel sohbet ─────────────────────────────────────────────────────

  /// `GET /api/chat/rooms`
  Future<List<ChatRoomSummary>> getRooms({
    String? category,
    String? type,
    bool withCounts = true,
  }) async {
    final res = await _dio.safeGet<dynamic>(
      ApiEndpoints.chatRooms,
      query: {
        if (withCounts) 'withCounts': 'true',
        if (category != null && category.isNotEmpty) 'category': category,
        if (type != null && type.isNotEmpty) 'type': type,
      },
    );
    final list = _extractList(
      res.data,
      keys: const ['rooms', 'items', 'data'],
    );
    return list
        .map(ChatRoomSummary.fromJson)
        .where((r) => r.id.isNotEmpty)
        .toList(growable: false);
  }

  /// `GET /api/chat/rooms/{roomId}/messages?page=1&limit=50`
  Future<ApiResponse<List<ChatServiceMessage>>> getMessages(
    String roomId, {
    int page = 1,
    int limit = 50,
    String? since,
  }) async {
    final res = await _dio.safeGet<dynamic>(
      ApiEndpoints.chatRoomMessages(roomId),
      query: apiPageQuery(page: page, limit: limit)
        ..addAll({
          if (since != null && since.isNotEmpty) 'since': since,
          if (since != null && since.isNotEmpty) 'after': since,
        }),
    );
    return parseResponseBody<List<ChatServiceMessage>>(
      res.data,
      fromData: (data) {
        final list = data is List
            ? asJsonList(data)
            : _extractList(data, keys: const ['messages', 'items', 'data']);
        return list
            .map(ChatServiceMessage.fromJson)
            .where((m) => m.id.isNotEmpty || m.content.isNotEmpty)
            .toList(growable: false);
      },
    );
  }

  /// `POST /api/chat/rooms/{roomId}/messages`
  Future<ChatServiceMessage> sendMessage(
    String roomId, {
    required String content,
    String type = 'text',
    String? nickname,
  }) async {
    final res = await _dio.safePost<dynamic>(
      ApiEndpoints.chatRoomMessages(roomId),
      data: jsonEncode({
        'content': content,
        'type': type,
        if (nickname != null && nickname.isNotEmpty) 'nickname': nickname,
      }),
      options: Options(contentType: 'application/json'),
    );
    final map = _unwrapMap(res.data);
    if (map != null) {
      final msg = map['message'];
      if (msg is Map) {
        return ChatServiceMessage.fromJson(Map<String, dynamic>.from(msg));
      }
      if (map['id'] != null) {
        return ChatServiceMessage.fromJson(map);
      }
    }
    return ChatServiceMessage(
      id: 'local-${DateTime.now().millisecondsSinceEpoch}',
      content: content,
      createdAt: DateTime.now(),
      type: type,
    );
  }

  /// `DELETE /api/chat/rooms/{roomId}/messages` veya `.../messages/{messageId}`
  Future<void> deleteMessage(String roomId, String messageId) async {
    try {
      await _dio.safeDelete<dynamic>(
        ApiEndpoints.chatRoomMessage(roomId, messageId),
      );
      return;
    } on ApiException catch (e) {
      if (e.statusCode != 404 && e.statusCode != 405) rethrow;
    }
    await _dio.safeDelete<dynamic>(
      ApiEndpoints.chatRoomMessages(roomId),
      data: jsonEncode({'messageId': messageId}),
      options: Options(contentType: 'application/json'),
    );
  }

  /// `POST /api/chat/rooms/{roomId}/presence` — `{action: "join"}`
  Future<List<ChatPresence>> joinRoom(
    String roomId, {
    String? nickname,
    String? password,
    int? seatIndex,
  }) async {
    final body = <String, dynamic>{
      'action': 'join',
      if (nickname != null && nickname.isNotEmpty) 'nickname': nickname,
      if (password != null && password.isNotEmpty) 'password': password,
      if (seatIndex != null && seatIndex >= 0) 'seatIndex': seatIndex,
    };
    final res = await _dio.safePost<dynamic>(
      ApiEndpoints.chatRoomPresence(roomId),
      data: jsonEncode(body),
      options: Options(contentType: 'application/json'),
    );
    return _presenceList(res.data);
  }

  /// `POST /api/chat/rooms/{roomId}/presence` — `{action: "leave"}` (DELETE yedek).
  Future<void> leaveRoom(String roomId) async {
    try {
      await _dio.safeDelete<dynamic>(
        '${ApiEndpoints.chatRoomPresence(roomId)}?leave=1',
      );
      return;
    } on ApiException catch (e) {
      if (e.statusCode != 404 && e.statusCode != 405) rethrow;
    }
    await _dio.safePost<dynamic>(
      ApiEndpoints.chatRoomPresence(roomId),
      data: jsonEncode({'action': 'leave'}),
      options: Options(contentType: 'application/json'),
    );
  }

  /// `POST /api/chat/rooms/{roomId}/typing`
  Future<void> sendTyping(String roomId, {bool isTyping = true}) async {
    await _dio.safePost<dynamic>(
      ApiEndpoints.chatRoomTyping(roomId),
      data: jsonEncode({'isTyping': isTyping}),
      options: Options(contentType: 'application/json'),
    );
  }

  /// `GET /api/chat/rooms/{roomId}/stream` — SSE.
  Stream<SseEvent> connectStream(String roomId, {String? connectionId}) {
    final client = _sseClient;
    if (client == null) {
      throw StateError(
        'SSE için ChatService oluşturulurken SseClient verilmelidir.',
      );
    }
    return client.chatRoom(roomId, connectionId: connectionId);
  }

  /// `POST /api/chat/rooms/{roomId}/gifts`
  Future<Map<String, dynamic>> sendGift(
    String roomId, {
    required String giftId,
    required String recipientId,
    int quantity = 1,
    String? battleId,
  }) async {
    final res = await _dio.safePost<dynamic>(
      ApiEndpoints.chatRoomGifts(roomId),
      data: {
        'giftId': giftId,
        'giftTypeId': giftId,
        'receiverUserId': recipientId,
        'receiverId': recipientId,
        'quantity': quantity,
        if (battleId != null && battleId.isNotEmpty) 'battleId': battleId,
        'platform': 'mobile',
      },
    );
    return _unwrapMap(res.data) ?? asJsonMap(res.data);
  }

  /// `GET /api/chat/rooms/{roomId}/gifts`
  Future<List<Map<String, dynamic>>> getGiftHistory(String roomId) async {
    final res = await _dio.safeGet<dynamic>(ApiEndpoints.chatRoomGifts(roomId));
    final list = _extractList(
      res.data,
      keys: const [
        'gifts',
        'history',
        'events',
        'leaderboard',
        'items',
        'data',
      ],
    );
    return list;
  }

  // ── 2. Ses & koltuk ─────────────────────────────────────────────────────

  /// `PATCH/POST /api/chat/rooms/{roomId}/seats` — kılavuz: `{action, seatIndex}`.
  Future<void> manageSeats(
    String roomId, {
    required String action,
    String? userId,
    int? seatIndex,
  }) async {
    final body = jsonEncode({
      'action': action,
      if (userId != null && userId.isNotEmpty) 'userId': userId,
      if (userId != null && userId.isNotEmpty) 'targetUserId': userId,
      if (seatIndex != null) 'seatIndex': seatIndex,
    });
    final opts = Options(contentType: 'application/json');
    try {
      await _dio.safePatch<dynamic>(
        ApiEndpoints.chatRoomSeats(roomId),
        data: body,
        options: opts,
      );
      return;
    } on ApiException catch (e) {
      if (e.statusCode != 404 && e.statusCode != 405) rethrow;
    }
    await _dio.safePost<dynamic>(
      ApiEndpoints.chatRoomSeats(roomId),
      data: body,
      options: opts,
    );
  }

  /// `POST /api/chat/rooms/{roomId}/voice` — `{action: "join"|"leave"}`.
  Future<void> voiceAction(String roomId, {required String action}) async {
    await _dio.safePost<dynamic>(
      ApiEndpoints.chatRoomVoice(roomId),
      data: jsonEncode({'action': action, 'type': action}),
      options: Options(contentType: 'application/json'),
    );
  }

  /// `POST /api/agora/token` — `{channelName, uid, role}`.
  Future<AgoraCredentials> fetchAgoraToken({
    required String channelName,
    required String role,
    int uid = 0,
  }) async {
    final res = await _dio.safePost<dynamic>(
      ApiEndpoints.agoraToken,
      data: {
        'channelName': channelName.trim(),
        'role': role,
        'uid': uid,
      },
    );
    final map = _unwrapMap(res.data);
    if (map == null) {
      throw const ApiException('Geçersiz Agora token yanıtı');
    }
    final cred = AgoraCredentials.fromJson(
      map,
      requestedChannel: channelName.trim(),
    );
    if (cred.token.isEmpty) {
      throw const ApiException('Agora token alınamadı');
    }
    return cred;
  }

  /// `POST /api/trtc/usersig` — üretim: `{userId, roomId}`.
  Future<TrtcCredentials> fetchTrtcUserSig({
    required String userId,
    required String roomId,
    int? sdkAppId,
    String? identifier,
  }) async {
    final res = await _dio.safePost<dynamic>(
      ApiEndpoints.trtcUserSig,
      data: {
        'userId': identifier ?? userId,
        'roomId': roomId,
        if (sdkAppId != null) 'sdkAppId': sdkAppId,
      },
    );
    final map = _unwrapMap(res.data);
    if (map == null) {
      throw const ApiException('Geçersiz TRTC yanıtı');
    }
    final cred = TrtcCredentials.fromJson(map, requestedRoomId: roomId);
    if (cred.userSig.isEmpty) {
      throw const ApiException('TRTC userSig alınamadı');
    }
    return cred;
  }

  // ── 3. DJ / müzik ───────────────────────────────────────────────────────

  /// `GET /api/chat/rooms/{roomId}/dj`
  Future<Map<String, dynamic>> getDJ(String roomId) async {
    final res = await _dio.safeGet<dynamic>(ApiEndpoints.chatRoomDj(roomId));
    return _unwrapMap(res.data) ?? asJsonMap(res.data);
  }

  /// `POST /api/chat/rooms/{roomId}/dj` — `{action, targetUserId?}`.
  Future<Map<String, dynamic>> djAction(
    String roomId, {
    required String action,
    String? targetUserId,
  }) async {
    final res = await _dio.safePost<dynamic>(
      ApiEndpoints.chatRoomDj(roomId),
      data: jsonEncode({
        'action': action,
        if (targetUserId != null && targetUserId.isNotEmpty)
          'targetUserId': targetUserId,
        if (targetUserId != null && targetUserId.isNotEmpty)
          'userId': targetUserId,
      }),
      options: Options(contentType: 'application/json'),
    );
    return _unwrapMap(res.data) ?? asJsonMap(res.data);
  }

  /// `GET /api/chat/rooms/{roomId}/music`
  Future<Map<String, dynamic>> getMusic(String roomId) async {
    final res = await _dio.safeGet<dynamic>(ApiEndpoints.chatRoomMusic(roomId));
    return _unwrapMap(res.data) ?? asJsonMap(res.data);
  }

  /// `POST /api/chat/rooms/{roomId}/music` — `{action: play|pause|skip, videoId?}`.
  Future<Map<String, dynamic>> controlMusic(
    String roomId, {
    required String action,
    String? videoId,
    String? title,
  }) async {
    if (action == 'pause' || action == 'stop') {
      try {
        await _dio.safeDelete<dynamic>(ApiEndpoints.chatRoomMusic(roomId));
      } on ApiException catch (e) {
        if (e.statusCode != 404 && e.statusCode != 405) rethrow;
      }
    }
    final res = await _dio.safePost<dynamic>(
      ApiEndpoints.chatRoomMusic(roomId),
      data: jsonEncode({
        'action': action,
        if (videoId != null && videoId.isNotEmpty) 'videoId': videoId,
        if (title != null && title.isNotEmpty) 'title': title,
        if (action == 'play') 'playing': true,
      }),
      options: Options(contentType: 'application/json'),
    );
    return _unwrapMap(res.data) ?? asJsonMap(res.data);
  }

  /// `GET /api/music/search?q=query`
  Future<List<ChatMusicHit>> searchMusic(String query) async {
    final q = query.trim();
    if (q.isEmpty) return const [];
    final res = await _dio.safeGet<dynamic>(
      ApiEndpoints.musicSearch,
      query: {'q': q},
    );
    final list = _extractList(
      res.data,
      keys: const ['results', 'items', 'songs', 'tracks', 'data'],
    );
    return list
        .map(ChatMusicHit.fromJson)
        .where((h) => h.videoId.isNotEmpty || h.title.isNotEmpty)
        .toList(growable: false);
  }

  /// `POST /api/chat/rooms/{roomId}/song-request`
  Future<Map<String, dynamic>> requestSong(
    String roomId, {
    required String songId,
    String? title,
    String? videoId,
  }) async {
    final vid = (videoId ?? songId).trim();
    final res = await _dio.safePost<dynamic>(
      ApiEndpoints.chatRoomSongRequest(roomId),
      data: jsonEncode({
        'videoId': vid,
        'songId': songId,
        if (title != null && title.isNotEmpty) 'title': title,
      }),
      options: Options(contentType: 'application/json'),
    );
    return _unwrapMap(res.data) ?? asJsonMap(res.data);
  }

  // ── 4. PK Battle ────────────────────────────────────────────────────────

  /// `GET /api/chat/rooms/{roomId}/pk`
  Future<Map<String, dynamic>> getPK(String roomId) async {
    final res = await _dio.safeGet<dynamic>(ApiEndpoints.chatRoomPk(roomId));
    return _unwrapMap(res.data) ?? asJsonMap(res.data);
  }

  /// `POST /api/chat/rooms/{roomId}/pk` veya respond/end alt uçları.
  Future<Map<String, dynamic>> pkAction(
    String roomId, {
    required String action,
    String? targetRoomId,
    String? guestUserId,
    String? inviteId,
    String? battleId,
    int? durationSec,
  }) async {
    final normalized = action.toLowerCase();
    if (normalized == 'accept' || normalized == 'reject') {
      final id = inviteId ?? battleId;
      if (id == null || id.isEmpty) {
        throw const ApiException('PK yanıtı için inviteId gerekli');
      }
      final res = await _dio.safePost<dynamic>(
        ApiEndpoints.chatRoomPkRespond(roomId, id),
        data: {'action': normalized},
      );
      return _unwrapMap(res.data) ?? asJsonMap(res.data);
    }
    if (normalized == 'end') {
      final id = battleId ?? inviteId;
      if (id == null || id.isEmpty) {
        throw const ApiException('PK bitişi için battleId gerekli');
      }
      final res = await _dio.safePost<dynamic>(
        ApiEndpoints.chatRoomPkEnd(roomId, id),
      );
      return _unwrapMap(res.data) ?? asJsonMap(res.data);
    }
    // Davet — kılavuz §9.3: yalnızca guestUserId + durationSec (action yok).
    final res = await _dio.safePost<dynamic>(
      ApiEndpoints.chatRoomPk(roomId),
      data: {
        if (guestUserId != null && guestUserId.isNotEmpty)
          'guestUserId': guestUserId,
        if (durationSec != null) 'durationSec': durationSec,
      },
    );
    return _unwrapMap(res.data) ?? asJsonMap(res.data);
  }

  /// `POST /api/chat/rooms/{roomId}/pk/score`
  Future<Map<String, dynamic>> updateScore(
    String roomId, {
    required int score,
    String? battleId,
    String? side,
  }) async {
    try {
      final res = await _dio.safePost<dynamic>(
        ApiEndpoints.chatRoomPkScore(roomId),
        data: {
          'score': score,
          if (battleId != null && battleId.isNotEmpty) 'battleId': battleId,
          if (side != null && side.isNotEmpty) 'side': side,
        },
      );
      return _unwrapMap(res.data) ?? asJsonMap(res.data);
    } on ApiException catch (e) {
      if (e.statusCode != 404 && e.statusCode != 405) rethrow;
      final res = await _dio.safePost<dynamic>(
        ApiEndpoints.videoStreamPkScore,
        data: {
          'roomId': roomId,
          'score': score,
          if (battleId != null && battleId.isNotEmpty) 'battleId': battleId,
        },
      );
      return _unwrapMap(res.data) ?? asJsonMap(res.data);
    }
  }

  // ── Yardımcılar ─────────────────────────────────────────────────────────

  static Map<String, dynamic>? _unwrapMap(dynamic body) {
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

  static List<Map<String, dynamic>> _extractList(
    dynamic body, {
    List<String> keys = const ['items', 'data'],
  }) {
    if (body is List) return asJsonList(body);
    final map = _unwrapMap(body) ?? (body is Map ? asJsonMap(body) : null);
    if (map != null) {
      for (final key in keys) {
        final raw = map[key];
        if (raw is List) return asJsonList(raw);
      }
    }
    return const [];
  }

  static List<ChatPresence> _presenceList(dynamic body) {
    final list = _extractList(
      body,
      keys: const [
        'users',
        'presence',
        'members',
        'onlineUsers',
        'viewers',
        'listeners',
        'data',
      ],
    );
    return list
        .map(ChatPresence.fromJson)
        .where((u) => u.id.isNotEmpty)
        .toList(growable: false);
  }
}
