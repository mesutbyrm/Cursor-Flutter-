import 'package:dio/dio.dart';

import '../../../../core/network/api_endpoints.dart';
import '../../../../core/network/dio_provider.dart';
import '../../../../core/util/json_util.dart';
import '../../domain/live_guest_list_snapshot.dart';

class LiveStreamExtrasDataSource {
  LiveStreamExtrasDataSource(this._dio);

  final Dio _dio;

  Future<int> fetchLikeCount(String streamId) async {
    try {
      final res = await _dio.safeGet<dynamic>(
        ApiEndpoints.videoStreamLike(streamId),
      );
      final body = res.data;
      if (body is Map) {
        return asInt(
          pick(Map<String, dynamic>.from(body), ['likeCount', 'count']),
        );
      }
    } catch (_) {}
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
    String? targetStreamId,
    String? battleId,
    int duration = 180,
  }) async {
    final normalized = action.toLowerCase();
    if (normalized == 'create' && targetStreamId != null) {
      final durationMinutes = (duration / 60).ceil().clamp(1, 60);
      try {
        final res = await _dio.safePost<dynamic>(
          ApiEndpoints.videoStreamPkBattle(streamId),
          data: {
            'opponentStreamId': targetStreamId,
            'durationMinutes': durationMinutes,
          },
        );
        final battle = _unwrapBattle(res.data);
        if (battle != null) return battle;
      } catch (_) {}
    }

    final body = <String, dynamic>{
      'action': action,
      'targetStreamId': ?targetStreamId,
      'battleId': ?battleId,
      if (action == 'create') 'streamId': streamId,
      if (action == 'create') 'duration': duration,
      if (action == 'create') 'durationSeconds': duration,
    };

    try {
      final res = await _dio.safePost<dynamic>(
        ApiEndpoints.videoStreamPk,
        data: body,
      );
      final battle = _unwrapBattle(res.data);
      if (battle != null) return battle;
    } catch (_) {}

    final res = await _dio.safePost<dynamic>(
      ApiEndpoints.videoStreamPkBattle(streamId),
      data: {
        'action': action,
        'targetStreamId': ?targetStreamId,
        'opponentStreamId': ?targetStreamId,
        'battleId': ?battleId,
        if (action == 'create') 'duration': duration,
      },
    );
    return _unwrapBattle(res.data);
  }

  Future<Map<String, dynamic>?> fetchPkBattle(String streamId) async {
    try {
      final res = await _dio.safeGet<dynamic>(
        ApiEndpoints.videoStreamPk,
        query: {'streamId': streamId},
      );
      final battle = _unwrapBattle(res.data);
      if (battle != null) return battle;
    } catch (_) {}

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
    if (body == null) return null;
    if (body is Map) {
      final map = Map<String, dynamic>.from(body);
      if (map.isEmpty) return null;
      final data = map['data'] is Map
          ? Map<String, dynamic>.from(map['data'] as Map)
          : map;
      final raw = data['battle'] ?? data['pk'];
      if (raw is Map) return Map<String, dynamic>.from(raw);
      if (data.containsKey('id') || data.containsKey('status')) {
        return data;
      }
    }
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
    Map<String, dynamic>? payload,
    String? receiverId,
    Map<String, dynamic>? data,
  }) async {
    await _dio.safePost<dynamic>(
      ApiEndpoints.videoStreamSignal(streamId),
      data: {
        'type': type,
        'receiverId': ?receiverId,
        'data': ?data,
        'payload': ?payload,
      },
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
      list ??= map['signals'] ?? map['items'];
    } else {
      list = body;
    }
    if (list is! List) return const [];
    return list
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
  }

  Future<List<Map<String, dynamic>>> fetchCoBroadcasters(
    String streamId,
  ) async {
    final snapshot = await fetchCoBroadcastSnapshot(streamId);
    return snapshot.coBroadcasters;
  }

  Future<({List<Map<String, dynamic>> coBroadcasters, List<Map<String, dynamic>> joinRequests})>
      fetchCoBroadcastSnapshot(String streamId) async {
    try {
      final res = await _dio.safeGet<dynamic>(
        ApiEndpoints.liveGuestList,
        query: {'streamId': streamId},
        forceRefresh: true,
      );
      if (res.data is Map) {
        final snap = LiveGuestListSnapshot.fromJson(
          asJsonMap(res.data),
        );
        final joinRequests = snap.toJoinRequests();
        // Misafir listesinde bekleyen istek yoksa co-broadcast uçuna düş.
        if (joinRequests.isNotEmpty || snap.guests.isNotEmpty) {
          if (joinRequests.isNotEmpty) {
            return (
              coBroadcasters: snap.toCoBroadcasters(),
              joinRequests: joinRequests,
            );
          }
          // Misafirler var ama istek yok — yine de co-broadcast'ten istekleri dene.
          try {
            final coRes = await _dio.safeGet<dynamic>(
              ApiEndpoints.videoStreamCoBroadcast(streamId),
            );
            return (
              coBroadcasters: snap.toCoBroadcasters(),
              joinRequests: _listFromBody(coRes.data,
                  keys: ['joinRequests', 'pendingRequests', 'requests']),
            );
          } catch (_) {
            return (
              coBroadcasters: snap.toCoBroadcasters(),
              joinRequests: const <Map<String, dynamic>>[],
            );
          }
        }
      }
    } catch (_) {}

    final res = await _dio.safeGet<dynamic>(
      ApiEndpoints.videoStreamCoBroadcast(streamId),
    );
    return (
      coBroadcasters: _listFromBody(res.data,
          keys: ['coBroadcasters', 'items', 'data', 'guests']),
      joinRequests: _listFromBody(res.data,
          keys: ['joinRequests', 'pendingRequests', 'requests']),
    );
  }

  Future<Map<String, dynamic>?> coBroadcastAction({
    required String streamId,
    required String action,
    String? userId,
  }) async {
    final res = await _dio.safePost<dynamic>(
      ApiEndpoints.videoStreamCoBroadcast(streamId),
      data: {
        'action': action,
        'userId': ?userId,
      },
    );
    return _unwrapCoBroadcaster(res.data);
  }

  Future<Map<String, dynamic>?> patchCoBroadcast({
    required String streamId,
    required String action,
  }) async {
    final res = await _dio.safePatch<dynamic>(
      ApiEndpoints.videoStreamCoBroadcast(streamId),
      data: {'action': action},
    );
    return _unwrapCoBroadcaster(res.data);
  }

  Future<Map<String, dynamic>?> inviteCoBroadcast({
    required String streamId,
    required String inviteeId,
  }) async {
    try {
      final res = await _dio.safePost<dynamic>(
        ApiEndpoints.videoStreamCoBroadcastInvite(streamId),
        data: {
          'userId': inviteeId,
          'inviteeId': inviteeId,
        },
      );
      return _unwrapCoBroadcaster(res.data);
    } catch (_) {
      return coBroadcastAction(
        streamId: streamId,
        action: 'invite',
        userId: inviteeId,
      );
    }
  }

  Future<List<Map<String, dynamic>>> fetchCoBroadcastInvites() async {
    final res = await _dio.safeGet<dynamic>(ApiEndpoints.coBroadcastInvites);
    return _listFromBody(res.data, keys: ['invites', 'items', 'data']);
  }

  Map<String, dynamic>? _unwrapCoBroadcaster(dynamic body) {
    if (body is! Map) return null;
    final map = Map<String, dynamic>.from(body);
    final data = map['data'] is Map
        ? Map<String, dynamic>.from(map['data'] as Map)
        : map;
    if (data.containsKey('id') && data.containsKey('status')) return data;
    final raw = data['coBroadcaster'] ?? data['invite'];
    if (raw is Map) return Map<String, dynamic>.from(raw);
    return data.containsKey('success') ? null : data;
  }

  List<Map<String, dynamic>> _listFromBody(
    dynamic body, {
    List<String> keys = const ['items', 'data'],
  }) {
    dynamic list = body;
    if (body is Map) {
      list = pick(Map<String, dynamic>.from(body), keys) ?? body;
    }
    if (list is! List) return const [];
    return list
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
  }

  Future<void> banViewer({
    required String streamId,
    required String userId,
    String? reason,
  }) async {
    await _dio.safePost<dynamic>(
      ApiEndpoints.videoStreamBan(streamId),
      data: {'userId': userId, 'reason': ?reason},
    );
  }

  Future<void> unbanViewer({
    required String streamId,
    required String userId,
  }) async {
    await _dio.safeDelete<dynamic>(
      '${ApiEndpoints.videoStreamBan(streamId)}?userId=$userId',
    );
  }

  Future<void> muteViewer({
    required String streamId,
    required String viewerId,
    String? reason,
    DateTime? expiresAt,
  }) async {
    await _dio.safePost<dynamic>(
      ApiEndpoints.videoStreamMute(streamId),
      data: {
        'viewerId': viewerId,
        'userId': viewerId,
        'reason': ?reason,
        if (expiresAt != null) 'expiresAt': expiresAt.toUtc().toIso8601String(),
      },
    );
  }

  Future<void> unmuteViewer({
    required String streamId,
    required String viewerId,
  }) async {
    await _dio.safeDelete<dynamic>(
      ApiEndpoints.videoStreamMute(streamId),
      data: {'viewerId': viewerId, 'userId': viewerId},
    );
  }

  Future<void> addModerator({
    required String streamId,
    required String userId,
  }) async {
    try {
      await _dio.safePost<dynamic>(
        ApiEndpoints.videoStreamModerators(streamId),
        data: {'userId': userId},
      );
    } catch (_) {
      await _dio.safePost<dynamic>(
        ApiEndpoints.videoStreamModerator(streamId),
        data: {'userId': userId},
      );
    }
  }

  Future<void> removeModerator({
    required String streamId,
    required String userId,
  }) async {
    try {
      await _dio.safeDelete<dynamic>(
        '${ApiEndpoints.videoStreamModerators(streamId)}?userId=$userId',
      );
    } catch (_) {
      await _dio.safeDelete<dynamic>(
        ApiEndpoints.videoStreamModerator(streamId),
        data: {'userId': userId},
      );
    }
  }

  Future<void> setBroadcastImage({
    required String streamId,
    required String imageUrl,
    bool isImageMode = true,
  }) async {
    try {
      await _dio.safePatch<dynamic>(
        ApiEndpoints.videoStream(streamId),
        data: {
          'broadcastImage': imageUrl,
          'isImageMode': isImageMode,
        },
      );
    } catch (_) {
      await _dio.safePost<dynamic>(
        ApiEndpoints.videoStreamImage(streamId),
        data: {'imageUrl': imageUrl, 'broadcastImage': imageUrl},
      );
    }
  }

  Future<void> setBackground({
    required String streamId,
    required String backgroundUrl,
  }) async {
    try {
      await _dio.safePatch<dynamic>(
        ApiEndpoints.videoStream(streamId),
        data: {'backgroundUrl': backgroundUrl},
      );
    } catch (_) {
      await _dio.safePost<dynamic>(
        ApiEndpoints.videoStreamBackground(streamId),
        data: {'backgroundUrl': backgroundUrl, 'imageUrl': backgroundUrl},
      );
    }
  }

  Future<void> triggerAutoClose(String streamId) async {
    await _dio.safePost<dynamic>(ApiEndpoints.videoStreamAutoClose(streamId));
  }
}
