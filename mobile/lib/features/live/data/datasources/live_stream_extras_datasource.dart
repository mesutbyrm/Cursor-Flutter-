import 'package:dio/dio.dart';

import '../../../../core/network/api_endpoints.dart';
import '../../../../core/network/dio_provider.dart';
import '../../../../core/util/json_util.dart';

class LiveStreamExtrasDataSource {
  LiveStreamExtrasDataSource(this._dio);

  final Dio _dio;

  Future<int> fetchLikeCount(String streamId) async {
    try {
      final res = await _dio.safeGet<dynamic>(
        ApiEndpoints.videoStream(streamId),
      );
      final body = res.data;
      if (body is Map) {
        final map = Map<String, dynamic>.from(body);
        final data = map['data'] is Map
            ? Map<String, dynamic>.from(map['data'] as Map)
            : map;
        final stream = data['stream'] ?? data;
        if (stream is Map) {
          return asInt(
            pick(Map<String, dynamic>.from(stream), ['likeCount', 'count']),
          );
        }
        return asInt(pick(data, ['likeCount', 'count']));
      }
    } catch (_) {}
    return 0;
  }

  Future<int> sendLike(String streamId, {int count = 1}) async {
    final res = await _dio.safePost<dynamic>(
      ApiEndpoints.videoStreamLike(streamId),
      data: {'count': count},
    );
    final body = res.data;
    if (body is Map) {
      final map = Map<String, dynamic>.from(body);
      final data = map['data'] is Map
          ? Map<String, dynamic>.from(map['data'] as Map)
          : map;
      return asInt(pick(data, ['likeCount', 'count']));
    }
    return 0;
  }

  Future<Map<String, dynamic>?> pkAction({
    required String streamId,
    required String action,
    String? opponentStreamId,
    String? opponentId,
  }) async {
    final res = await _dio.safePost<dynamic>(
      ApiEndpoints.videoStreamPkBattle(streamId),
      data: {
        'action': action,
        if (opponentStreamId != null) 'opponentStreamId': opponentStreamId,
        if (opponentId != null) 'opponentId': opponentId,
      },
    );
    return _unwrapBattle(res.data);
  }

  Future<Map<String, dynamic>?> fetchPkBattle(String streamId) async {
    try {
      final res = await _dio.safeGet<dynamic>(
        ApiEndpoints.videoStreamPkBattle(streamId),
      );
      return _unwrapBattle(res.data);
    } catch (_) {
      return null;
    }
  }

  Map<String, dynamic>? _unwrapBattle(dynamic body) {
    if (body is! Map) return null;
    final map = Map<String, dynamic>.from(body);
    final data = map['data'] is Map
        ? Map<String, dynamic>.from(map['data'] as Map)
        : map;
    final raw = data['battle'] ?? data['pk'];
    if (raw is Map) return Map<String, dynamic>.from(raw);
    return null;
  }

  Future<List<Map<String, dynamic>>> pollSignals(
    String streamId, {
    String? since,
  }) async {
    final res = await _dio.safeGet<dynamic>(
      ApiEndpoints.videoStreamSignal(streamId),
      query: since != null && since.isNotEmpty ? {'since': since} : null,
    );
    return _signalList(res.data);
  }

  Future<void> postSignal({
    required String streamId,
    required String type,
    required Map<String, dynamic> payload,
  }) async {
    await _dio.safePost<dynamic>(
      ApiEndpoints.videoStreamSignal(streamId),
      data: {'type': type, 'payload': payload},
    );
  }

  List<Map<String, dynamic>> _signalList(dynamic body) {
    dynamic list;
    if (body is Map) {
      final map = Map<String, dynamic>.from(body);
      final data = map['data'] is Map ? map['data'] : map;
      if (data is Map) {
        list = pick(Map<String, dynamic>.from(data), ['signals', 'items']);
      }
    } else {
      list = body;
    }
    if (list is! List) return const [];
    return list
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
  }

  Future<Map<String, dynamic>?> inviteCoBroadcast({
    required String streamId,
    required String inviteeId,
  }) async {
    final res = await _dio.safePost<dynamic>(
      ApiEndpoints.videoStreamCoBroadcastInvite(streamId),
      data: {'inviteeId': inviteeId},
    );
    return _unwrapInvite(res.data);
  }

  Future<Map<String, dynamic>?> respondCoBroadcast({
    required String streamId,
    required String inviteId,
    required bool accept,
  }) async {
    final res = await _dio.safePost<dynamic>(
      ApiEndpoints.videoStreamCoBroadcast(streamId),
      data: {'inviteId': inviteId, 'accept': accept},
    );
    return _unwrapInvite(res.data);
  }

  Future<List<Map<String, dynamic>>> fetchCoBroadcastInvites() async {
    final res = await _dio.safeGet<dynamic>(ApiEndpoints.coBroadcastInvites);
    dynamic list;
    if (res.data is Map) {
      final map = Map<String, dynamic>.from(res.data as Map);
      list = pick(map, ['invites', 'items', 'data']);
    } else {
      list = res.data;
    }
    if (list is! List) return const [];
    return list
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
  }

  Map<String, dynamic>? _unwrapInvite(dynamic body) {
    if (body is! Map) return null;
    final map = Map<String, dynamic>.from(body);
    final data = map['data'] is Map
        ? Map<String, dynamic>.from(map['data'] as Map)
        : map;
    final raw = data['invite'];
    if (raw is Map) return Map<String, dynamic>.from(raw);
    return null;
  }

  Future<void> banViewer({
    required String streamId,
    required String userId,
    String? reason,
  }) async {
    await _dio.safePost<dynamic>(
      ApiEndpoints.videoStreamBan(streamId),
      data: {'userId': userId, if (reason != null) 'reason': reason},
    );
  }

  Future<void> muteViewer({
    required String streamId,
    required String userId,
    int minutes = 30,
    String? reason,
  }) async {
    await _dio.safePost<dynamic>(
      ApiEndpoints.videoStreamMute(streamId),
      data: {
        'userId': userId,
        'minutes': minutes,
        'durationMinutes': minutes,
        if (reason != null) 'reason': reason,
      },
    );
  }

  Future<void> addModerator({
    required String streamId,
    required String userId,
  }) async {
    await _dio.safePost<dynamic>(
      ApiEndpoints.videoStreamModerator(streamId),
      data: {'userId': userId},
    );
  }

  Future<void> setBroadcastImage({
    required String streamId,
    required String imageUrl,
  }) async {
    await _dio.safePost<dynamic>(
      ApiEndpoints.videoStreamImage(streamId),
      data: {'imageUrl': imageUrl, 'broadcastImage': imageUrl},
    );
  }

  Future<void> setBackground({
    required String streamId,
    required String backgroundUrl,
  }) async {
    await _dio.safePost<dynamic>(
      ApiEndpoints.videoStreamBackground(streamId),
      data: {'backgroundUrl': backgroundUrl, 'imageUrl': backgroundUrl},
    );
  }

  Future<void> triggerAutoClose(String streamId) async {
    await _dio.safePost<dynamic>(ApiEndpoints.videoStreamAutoClose(streamId));
  }
}
