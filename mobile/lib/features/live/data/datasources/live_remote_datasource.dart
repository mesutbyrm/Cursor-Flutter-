import 'package:dio/dio.dart';

import '../../../../core/config/env.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/network/dio_provider.dart';
import '../../../../core/network/live_debug_log.dart';
import '../../../../core/util/json_util.dart';
import '../models/live_stream_dto.dart';
import '../../domain/entities/live_stream_chat_message.dart';
import '../../domain/entities/live_stream_entity.dart';

class LiveRemoteDataSource {
  LiveRemoteDataSource(this._dio);

  final Dio _dio;

  static const int _pageSize = 30;

  Future<List<LiveStreamEntity>> fetch({int page = 1, String? category}) async {
    final query = <String, String>{
      'limit': '$_pageSize',
      'page': '$page',
      if (category != null && category.isNotEmpty) 'category': category,
    };
    if (Env.useMobileAuth) {
      final res = await _dio.safeGet<dynamic>(
        ApiEndpoints.videoStreams,
        query: query,
      );
      return _parseStreamList(res.data);
    }
    final res = await _dio.safeGet<dynamic>(
      ApiEndpoints.liveStreams,
      query: {'page': page, 'limit': 30},
    );
    return _parseStreamList(res.data);
  }

  List<LiveStreamEntity> _parseStreamList(dynamic body) {
    dynamic list;
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
    } else {
      list = body;
    }
    return asJsonList(list)
        .map((j) {
          final map = asJsonMap(j);
          final base = LiveStreamDto.fromApiMap(map).toEntity();
          final playback = LiveStreamDto.playbackUrlFrom(map);
          final tags = _parseTags(map);
          final isPk = _boolFlag(map, ['isPk', 'isPkLive', 'pkActive', 'inPk']);
          final isVip = _boolFlag(map, ['isVip', 'isVipHost', 'vipHost']);
          return LiveStreamEntity(
            id: base.id,
            title: base.title,
            streamerName: base.streamerName,
            thumbnailUrl: base.thumbnailUrl,
            category: base.category,
            viewerCount: base.viewerCount,
            isLive: base.isLive,
            hostUserId: base.hostUserId,
            playbackUrl: playback,
            tags: tags,
            isPkLive: isPk,
            isVipHost: isVip,
          );
        })
        .where((s) => s.id.isNotEmpty)
        .toList();
  }

  List<String> _parseTags(Map<String, dynamic> map) {
    final raw = pick(map, ['tags', 'labels']);
    if (raw is List) {
      return raw.map((e) => e.toString()).where((s) => s.isNotEmpty).toList();
    }
    final single = pick(map, ['tag', 'subcategory'])?.toString();
    if (single != null && single.isNotEmpty) return [single];
    return const [];
  }

  bool _boolFlag(Map<String, dynamic> map, List<String> keys) {
    final v = pick(map, keys);
    if (v is bool) return v;
    if (v is num) return v != 0;
    final s = v?.toString().toLowerCase();
    return s == 'true' || s == '1' || s == 'yes';
  }

  Future<LiveStreamEntity?> fetchStream(String streamId) async {
    if (!Env.useMobileAuth) return null;
    try {
      final res = await _dio.safeGet<dynamic>(
        ApiEndpoints.videoStream(streamId),
      );
      final body = res.data;
      if (body is Map<String, dynamic>) {
        final raw = body['stream'] ?? body['data'] ?? body;
        if (raw is Map) {
          return LiveStreamDto.fromApiMap(Map<String, dynamic>.from(raw))
              .toEntity();
        }
      }
    } catch (_) {}
    return null;
  }

  Future<int> joinVideoStream(String streamId) async {
    LiveDebugLog.log('stream.join', {'streamId': streamId});
    final res = await _dio.safePost<dynamic>(
      ApiEndpoints.videoStreamJoin(streamId),
    );
    final body = res.data;
    if (body is Map) {
      final map = Map<String, dynamic>.from(body);
      final data = map['data'] is Map
          ? Map<String, dynamic>.from(map['data'] as Map)
          : map;
      return asInt(pick(data, ['viewerCount', 'viewers', 'watching']));
    }
    return 0;
  }

  Future<void> leaveVideoStream(String streamId) async {
    try {
      await _dio.safePost<dynamic>(ApiEndpoints.videoStreamLeave(streamId));
      LiveDebugLog.log('stream.leave', {'streamId': streamId});
    } catch (_) {}
  }

  Future<List<LiveStreamChatMessage>> fetchStreamMessages(
    String streamId, {
    DateTime? since,
  }) async {
    final res = await _dio.safeGet<dynamic>(
      ApiEndpoints.videoStreamMessages(streamId),
      query: since != null
          ? {'since': since.toUtc().toIso8601String()}
          : null,
    );
    return _parseStreamMessages(res.data);
  }

  Future<LiveStreamChatMessage?> sendStreamMessage({
    required String streamId,
    required String content,
  }) async {
    LiveDebugLog.log('stream.chat.send', {'streamId': streamId});
    final res = await _dio.safePost<dynamic>(
      ApiEndpoints.videoStreamMessages(streamId),
      data: {'content': content.trim()},
    );
    final body = res.data;
    if (body is Map) {
      final map = Map<String, dynamic>.from(body);
      final raw = map['message'] ?? map['data'];
      if (raw is Map) {
        return LiveStreamChatMessage.fromJson(
          Map<String, dynamic>.from(raw),
        );
      }
    }
    return null;
  }

  List<LiveStreamChatMessage> _parseStreamMessages(dynamic body) {
    dynamic list;
    if (body is Map) {
      final map = Map<String, dynamic>.from(body);
      if (map['success'] == true && map['data'] != null) {
        return _parseStreamMessages(map['data']);
      }
      list = pick(map, ['messages', 'items', 'data']);
    } else {
      list = body;
    }
    if (list is! List) return const [];
    return list
        .whereType<Map>()
        .map((e) => LiveStreamChatMessage.fromJson(
              Map<String, dynamic>.from(e),
            ))
        .where((m) => m.content.isNotEmpty)
        .toList();
  }

  Future<String> createVideoStream({
    required String title,
    String? description,
    String? category,
    List<String>? tags,
    String? thumbnailUrl,
    bool isPrivate = false,
    bool isImageMode = false,
    String? backgroundUrl,
  }) async {
    final started = DateTime.now();
    LiveDebugLog.log('create.request', {'title': title});
    final res = await _dio.safePost<dynamic>(
      ApiEndpoints.videoStreams,
      data: {
        'title': title,
        'name': title,
        if (description != null && description.isNotEmpty)
          'description': description,
        if (category != null && category.isNotEmpty) 'category': category,
        if (tags != null && tags.isNotEmpty) 'tags': tags,
        if (thumbnailUrl != null && thumbnailUrl.isNotEmpty)
          'thumbnailUrl': thumbnailUrl,
        if (thumbnailUrl != null && thumbnailUrl.isNotEmpty)
          'coverUrl': thumbnailUrl,
        if (thumbnailUrl != null && thumbnailUrl.isNotEmpty)
          'broadcastImage': thumbnailUrl,
        if (backgroundUrl != null && backgroundUrl.isNotEmpty)
          'backgroundUrl': backgroundUrl,
        'isPrivate': isPrivate,
        'private': isPrivate,
        'isImageMode': isImageMode,
        'requestType': 'live',
        'status': 'live',
      },
    );
    final streamId = _extractStreamId(res.data);
    if (streamId == null || streamId.isEmpty) {
      throw ApiException(
        'Yayın oluşturuldu ancak oda kimliği alınamadı. '
        'Yanıt: ${res.statusCode}',
      );
    }
    LiveDebugLog.log('create.ok', {
      'streamId': streamId,
      'elapsedMs': DateTime.now().difference(started).inMilliseconds,
    });
    return streamId;
  }

  /// Agora bağlandıktan sonra çağır — takipçilere push bildirimi.
  Future<int> notifyLiveStarted(String streamId) async {
    try {
      final res = await _dio.safePost<dynamic>(
        ApiEndpoints.videoStreamLiveStarted(streamId),
        data: const {},
      );
      LiveDebugLog.log('live-started.ok', {'streamId': streamId});
      final body = res.data;
      if (body is Map) {
        return asInt(pick(Map<String, dynamic>.from(body), ['notifiedCount']));
      }
      return 0;
    } catch (e) {
      LiveDebugLog.log('live-started.fail', {
        'streamId': streamId,
        'reason': ApiException.userMessage(e),
      });
      rethrow;
    }
  }

  Future<void> updateVideoStream(
    String streamId, {
    String? title,
    String? description,
    String? broadcastImage,
    bool? isImageMode,
    String? backgroundUrl,
  }) async {
    await _dio.safePatch<dynamic>(
      ApiEndpoints.videoStream(streamId),
      data: {
        'title': ?title,
        'description': ?description,
        'broadcastImage': ?broadcastImage,
        'isImageMode': ?isImageMode,
        'backgroundUrl': ?backgroundUrl,
      },
    );
  }

  Future<List<Map<String, dynamic>>> fetchStreamViewers(String streamId) async {
    try {
      final res = await _dio.safeGet<dynamic>(
        ApiEndpoints.videoStreamViewers(streamId),
      );
      final body = res.data;
      dynamic list = body;
      if (body is Map) {
        list = pick(Map<String, dynamic>.from(body), ['viewers', 'items', 'data']) ?? body;
      }
      if (list is! List) return const [];
      return list
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
    } catch (_) {
      return const [];
    }
  }

  String? _extractStreamId(dynamic body) {
    if (body is String && body.trim().isNotEmpty && !body.contains('<html')) {
      return body.trim();
    }
    Map<String, dynamic>? map;
    if (body is Map<String, dynamic>) {
      map = body;
    } else if (body is Map) {
      map = Map<String, dynamic>.from(body);
    }
    if (map == null) return null;
    if (map['success'] == true && map['data'] != null) {
      return _extractStreamId(map['data']);
    }
    final streamObj = map['stream'] ?? map['videoStream'] ?? map['broadcast'];
    if (streamObj is Map) {
      final nested = _extractStreamId(streamObj);
      if (nested != null) return nested;
    }
    final id = pick(map, ['id', '_id', 'streamId', 'roomId']);
    return id?.toString();
  }

  Future<void> endVideoStream(String streamId) async {
    try {
      await _dio.safePost<dynamic>(ApiEndpoints.videoStreamEnd(streamId));
    } catch (_) {
      await _dio.safeDelete<dynamic>('/api/video-streams/$streamId');
    }
  }
}
