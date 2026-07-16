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
import 'models/stream_comment.dart';
import 'models/stream_summary.dart';

/// Canlifal canlı yayın API — kılavuz §9.4 `LiveStreamRepository`.
///
/// Base URL: `https://canlifal.com` · Auth: JWT Bearer (bazı uçlar public)
class StreamService {
  StreamService({
    required Dio Function() resolveAuthedDio,
    SseClient? sseClient,
  })  : _resolveAuthedDio = resolveAuthedDio,
        _sseClient = sseClient;

  final Dio Function() _resolveAuthedDio;
  final SseClient? _sseClient;

  Dio get _dio => _resolveAuthedDio();

  // ── 1. Temel yayın ──────────────────────────────────────────────────────

  /// `GET /api/video-streams?page=1&limit=20`
  Future<ApiResponse<List<StreamSummary>>> getStreams({
    int page = 1,
    int limit = 20,
    String? category,
  }) async {
    final res = await _dio.safeGet<dynamic>(
      ApiEndpoints.videoStreams,
      query: apiPageQuery(page: page, limit: limit)
        ..addAll({
          if (category != null && category.isNotEmpty) 'category': category,
        }),
    );
    return parseResponse<List<StreamSummary>>(
      res.data,
      fromData: (data) => _parseStreamList(data),
    );
  }

  /// `POST /api/video-streams`
  Future<String> startStream({
    required String title,
    String? category,
    String? thumbnail,
    String? description,
  }) async {
    final res = await _dio.safePost<dynamic>(
      ApiEndpoints.videoStreams,
      data: {
        'title': title.trim(),
        'name': title.trim(),
        if (description != null && description.isNotEmpty)
          'description': description,
        if (category != null && category.isNotEmpty) 'category': category,
        if (thumbnail != null && thumbnail.isNotEmpty) ...{
          'thumbnailUrl': thumbnail,
          'coverUrl': thumbnail,
          'broadcastImage': thumbnail,
        },
        'requestType': 'live',
        'status': 'live',
      },
    );
    final streamId = _extractStreamId(res.data);
    if (streamId == null || streamId.isEmpty) {
      throw const ApiException('Yayın oluşturuldu ancak streamId alınamadı');
    }
    return streamId;
  }

  /// `GET /api/video-streams/{streamId}`
  Future<StreamSummary?> getStream(String streamId) async {
    final res = await _dio.safeGet<dynamic>(
      ApiEndpoints.videoStream(streamId),
    );
    final map = _unwrapMap(res.data);
    if (map == null) return null;
    final raw = map['stream'] ?? map['videoStream'] ?? map;
    if (raw is Map) {
      return StreamSummary.fromJson(Map<String, dynamic>.from(raw));
    }
    return StreamSummary.fromJson(map);
  }

  /// `POST /api/video-streams/{streamId}/end`
  Future<void> endStream(String streamId) async {
    try {
      await _dio.safePost<dynamic>(ApiEndpoints.videoStreamEnd(streamId));
    } on ApiException catch (e) {
      if (e.statusCode != 404 && e.statusCode != 405) rethrow;
      await _dio.safeDelete<dynamic>(ApiEndpoints.videoStream(streamId));
    }
  }

  /// `POST /api/video-streams/{streamId}/join`
  Future<int> joinStream(String streamId, {String? nickname}) async {
    final res = await _dio.safePost<dynamic>(
      ApiEndpoints.videoStreamJoin(streamId),
      data: nickname != null && nickname.isNotEmpty
          ? {'nickname': nickname}
          : null,
    );
    final map = _unwrapMap(res.data) ?? asJsonMap(res.data);
    return asInt(
      pick(map, ['viewerCount', 'viewers', 'watching', 'count']),
    );
  }

  /// `DELETE /api/video-streams/{streamId}/join` — kılavuz yedek: `POST .../leave`.
  Future<void> leaveStream(String streamId) async {
    try {
      await _dio.safeDelete<dynamic>(ApiEndpoints.videoStreamJoin(streamId));
      return;
    } on ApiException catch (e) {
      if (e.statusCode != 404 && e.statusCode != 405) rethrow;
    }
    try {
      await _dio.safePost<dynamic>(ApiEndpoints.videoStreamLeave(streamId));
    } catch (_) {}
  }

  /// `GET /api/video-streams/{streamId}/stream` — SSE.
  Stream<SseEvent> connectStream(String streamId, {String? connectionId}) {
    final client = _sseClient;
    if (client == null) {
      throw StateError(
        'SSE için StreamService oluşturulurken SseClient verilmelidir.',
      );
    }
    return client.videoStream(streamId, connectionId: connectionId);
  }

  /// `POST /api/video-streams/{streamId}/comments`
  Future<StreamComment> sendComment(
    String streamId, {
    required String text,
    String? nickname,
    bool isHidden = false,
  }) async {
    final res = await _dio.safePost<dynamic>(
      ApiEndpoints.videoStreamComments(streamId),
      data: jsonEncode({
        'content': text.trim(),
        if (nickname != null && nickname.isNotEmpty) 'nickname': nickname,
        if (isHidden) 'isHidden': true,
      }),
      options: Options(contentType: 'application/json'),
    );
    final map = _unwrapMap(res.data) ?? asJsonMap(res.data);
    final raw = map['comment'] ?? map['message'] ?? map;
    if (raw is Map) {
      return StreamComment.fromJson(Map<String, dynamic>.from(raw));
    }
    return StreamComment(
      id: 'local-${DateTime.now().millisecondsSinceEpoch}',
      content: text.trim(),
      createdAt: DateTime.now(),
    );
  }

  /// `POST /api/video-streams/{streamId}/gifts`
  Future<Map<String, dynamic>> sendGift(
    String streamId, {
    required String giftId,
    int quantity = 1,
    String? receiverUserId,
    String? pkMatchId,
  }) async {
    final res = await _dio.safePost<dynamic>(
      ApiEndpoints.videoStreamGifts(streamId),
      data: {
        'giftId': giftId,
        'giftTypeId': giftId,
        'quantity': quantity,
        'platform': 'mobile',
        if (receiverUserId != null && receiverUserId.isNotEmpty)
          'toUserId': receiverUserId,
        if (receiverUserId != null && receiverUserId.isNotEmpty)
          'receiverUserId': receiverUserId,
        if (pkMatchId != null && pkMatchId.isNotEmpty) 'pkMatchId': pkMatchId,
      },
    );
    return _unwrapMap(res.data) ?? asJsonMap(res.data);
  }

  /// `POST /api/video-streams/{streamId}/like`
  Future<int> likeStream(String streamId, {int count = 1}) async {
    final res = await _dio.safePost<dynamic>(
      ApiEndpoints.videoStreamLike(streamId),
      data: {'count': count},
    );
    final map = _unwrapMap(res.data) ?? asJsonMap(res.data);
    return asInt(pick(map, ['likeCount', 'count', 'likes']));
  }

  // ── 2. Co-Broadcast ─────────────────────────────────────────────────────

  /// `GET /api/video-streams/{streamId}/co-broadcast`
  Future<Map<String, dynamic>> getCoStatus(String streamId) async {
    try {
      final res = await _dio.safeGet<dynamic>(
        ApiEndpoints.videoStreamCoBroadcast(streamId),
        forceRefresh: true,
      );
      return _coStatusFromBody(res.data);
    } on ApiException catch (e) {
      if (e.statusCode != 404 && e.statusCode != 405) rethrow;
    }
    final res = await _dio.safeGet<dynamic>(
      ApiEndpoints.liveGuestList,
      query: {'streamId': streamId},
      forceRefresh: true,
    );
    final map = _unwrapMap(res.data) ?? asJsonMap(res.data);
    return {
      'coBroadcasters': _extractList(
        map,
        keys: const ['coBroadcasters', 'guests', 'items', 'data'],
      ),
      'joinRequests': const <Map<String, dynamic>>[],
    };
  }

  /// `POST /api/video-streams/{streamId}/co-broadcast` — `{action: "join"|"request"}`.
  Future<Map<String, dynamic>> joinCo(
    String streamId, {
    String action = 'request',
    String? userId,
  }) async {
    final res = await _dio.safePost<dynamic>(
      ApiEndpoints.videoStreamCoBroadcast(streamId),
      data: {
        'action': action,
        if (userId != null && userId.isNotEmpty) 'userId': userId,
      },
    );
    return _unwrapMap(res.data) ?? asJsonMap(res.data);
  }

  /// `POST /api/video-streams/{streamId}/co-broadcast/invite`
  Future<Map<String, dynamic>> inviteCo(
    String streamId, {
    required String userId,
  }) async {
    try {
      final res = await _dio.safePost<dynamic>(
        ApiEndpoints.videoStreamCoBroadcastInvite(streamId),
        data: {'userId': userId, 'inviteeId': userId},
      );
      return _unwrapMap(res.data) ?? asJsonMap(res.data);
    } on ApiException catch (e) {
      if (e.statusCode != 404 && e.statusCode != 405) rethrow;
      return joinCo(streamId, action: 'invite', userId: userId);
    }
  }

  // ── 3. Moderasyon ───────────────────────────────────────────────────────

  /// `GET /api/video-streams/{streamId}/moderators`
  Future<List<Map<String, dynamic>>> getMods(String streamId) async {
    try {
      final res = await _dio.safeGet<dynamic>(
        ApiEndpoints.videoStreamModerators(streamId),
      );
      return _extractList(
        res.data,
        keys: const ['moderators', 'mods', 'items', 'data'],
      );
    } on ApiException catch (e) {
      if (e.statusCode != 404 && e.statusCode != 405) rethrow;
      final res = await _dio.safeGet<dynamic>(
        ApiEndpoints.videoStreamModerator(streamId),
      );
      return _extractList(
        res.data,
        keys: const ['moderators', 'mods', 'items', 'data'],
      );
    }
  }

  /// `POST /api/video-streams/{streamId}/moderators`
  Future<void> addMod(String streamId, {required String userId}) async {
    try {
      await _dio.safePost<dynamic>(
        ApiEndpoints.videoStreamModerators(streamId),
        data: {'userId': userId},
      );
    } on ApiException catch (e) {
      if (e.statusCode != 404 && e.statusCode != 405) rethrow;
      await _dio.safePost<dynamic>(
        ApiEndpoints.videoStreamModerator(streamId),
        data: {'userId': userId},
      );
    }
  }

  /// `POST /api/video-streams/{streamId}/mute`
  Future<void> muteUser(
    String streamId, {
    required String userId,
    String? reason,
  }) async {
    await _dio.safePost<dynamic>(
      ApiEndpoints.videoStreamMute(streamId),
      data: {
        'userId': userId,
        'viewerId': userId,
        if (reason != null && reason.isNotEmpty) 'reason': reason,
      },
    );
  }

  /// `POST /api/video-streams/{streamId}/ban`
  Future<void> banUser(
    String streamId, {
    required String userId,
    String? reason,
  }) async {
    await _dio.safePost<dynamic>(
      ApiEndpoints.videoStreamBan(streamId),
      data: {
        'userId': userId,
        if (reason != null && reason.isNotEmpty) 'reason': reason,
      },
    );
  }

  // ── 4. RTC ──────────────────────────────────────────────────────────────

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
  }) async {
    final res = await _dio.safePost<dynamic>(
      ApiEndpoints.trtcUserSig,
      data: {
        'userId': userId,
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

  static List<StreamSummary> _parseStreamList(dynamic body) {
    dynamic list = body;
    if (body is Map<String, dynamic>) {
      if (body['success'] == true && body['data'] != null) {
        return _parseStreamList(body['data']);
      }
      list = pick(body, [
        'videoStreams',
        'streams',
        'items',
        'data',
        'results',
        'lives',
      ]);
    }
    if (list is! List) return const [];
    return asJsonList(list)
        .map(StreamSummary.fromJson)
        .where((s) => s.id.isNotEmpty)
        .toList(growable: false);
  }

  static String? _extractStreamId(dynamic body) {
    if (body is String && body.trim().isNotEmpty && !body.contains('<html')) {
      return body.trim();
    }
    final map = _unwrapMap(body) ?? (body is Map ? asJsonMap(body) : null);
    if (map == null) return null;
    final streamObj = map['stream'] ?? map['videoStream'] ?? map['broadcast'];
    if (streamObj is Map) {
      final nested = _extractStreamId(streamObj);
      if (nested != null) return nested;
    }
    return pick(map, ['id', '_id', 'streamId', 'roomId'])?.toString();
  }

  static Map<String, dynamic> _coStatusFromBody(dynamic body) {
    final map = _unwrapMap(body) ?? asJsonMap(body);
    return {
      'coBroadcasters': _extractList(
        map,
        keys: const ['coBroadcasters', 'guests', 'items', 'data'],
      ),
      'joinRequests': _extractList(
        map,
        keys: const ['joinRequests', 'pendingRequests', 'requests'],
      ),
      if (map.isNotEmpty) 'raw': map,
    };
  }
}
