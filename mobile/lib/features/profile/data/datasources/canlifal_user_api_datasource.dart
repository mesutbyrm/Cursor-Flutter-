import 'dart:convert';

import 'package:dio/dio.dart';

import '../../../../core/network/api_endpoints.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/network/dio_provider.dart';
import '../../../../core/util/json_util.dart';
import '../../../auth/data/models/user_dto.dart';
import '../../../auth/domain/entities/user_entity.dart';
import '../../domain/entities/broadcast_history_item.dart';
import '../../domain/entities/user_activity_item.dart';

/// canlifal.com Flutter API dokümanı — kullanıcı lookup, aktivite, yayın geçmişi.
class CanlifalUserApiDataSource {
  CanlifalUserApiDataSource(this._dio);

  final Dio _dio;

  /// `GET /api/users/lookup/{username}`
  Future<UserEntity> lookupByUsername(String username) async {
    final name = username.trim();
    if (name.isEmpty) {
      throw const ApiException('Kullanıcı adı gerekli');
    }
    final res = await _dio.safeGet<dynamic>(
      ApiEndpoints.userLookup(name),
    );
    final body = res.data;
    if (body is Map) {
      final map = asJsonMap(body);
      final err = map['error'];
      if (err != null) {
        throw ApiException(err.toString());
      }
      final userRaw = map['user'] ?? map['data'] ?? map;
      if (userRaw is Map) {
        return UserDto.fromJson(asJsonMap(userRaw)).toEntity();
      }
    }
    throw const ApiException('Kullanıcı bulunamadı');
  }

  /// `GET /api/user/broadcast-history?page=1&limit=20&status=ended`
  Future<List<BroadcastHistoryItem>> broadcastHistory({
    int page = 1,
    int limit = 20,
    String status = 'ended',
  }) async {
    final res = await _dio.safeGet<dynamic>(
      ApiEndpoints.userBroadcastHistory,
      query: {
        'page': page,
        'limit': limit,
        if (status.isNotEmpty) 'status': status,
      },
    );
    return _parseBroadcastHistory(res.data);
  }

  /// `GET /api/user/activity?unread=true`
  Future<List<UserActivityItem>> fetchActivity({bool unreadOnly = false}) async {
    final res = await _dio.safeGet<dynamic>(
      ApiEndpoints.userActivity,
      query: unreadOnly ? {'unread': 'true'} : null,
    );
    return _parseActivityList(res.data);
  }

  /// `PATCH /api/user/activity` — `{"markAllRead": true}`
  Future<void> markAllActivityRead() async {
    await _dio.safePatch<dynamic>(
      ApiEndpoints.userActivity,
      data: jsonEncode({'markAllRead': true}),
      options: Options(contentType: 'application/json'),
    );
  }

  List<BroadcastHistoryItem> _parseBroadcastHistory(dynamic body) {
    dynamic raw;
    if (body is Map) {
      final map = asJsonMap(body);
      if (map['error'] != null) {
        throw ApiException(map['error'].toString());
      }
      raw = map['items'] ??
          map['broadcasts'] ??
          map['history'] ??
          map['data'];
      if (raw is Map) {
        raw = raw['items'] ?? raw['broadcasts'] ?? raw['history'];
      }
    } else if (body is List) {
      raw = body;
    }
    if (raw is! List) return const [];
    return raw.map((e) {
      final m = asJsonMap(e);
      return BroadcastHistoryItem(
        id: pick(m, ['id', '_id', 'streamId'])?.toString() ?? '',
        title: pick(m, ['title', 'name', 'nameTr'])?.toString() ?? 'Yayın',
        status: pick(m, ['status', 'state'])?.toString(),
        thumbnailUrl: pick(m, [
          'thumbnail',
          'thumbUrl',
          'coverImage',
          'broadcastImage',
          'image',
        ])?.toString(),
        startedAt: DateTime.tryParse(
          pick(m, ['startedAt', 'startTime', 'createdAt'])?.toString() ?? '',
        ),
        endedAt: DateTime.tryParse(
          pick(m, ['endedAt', 'endTime', 'finishedAt'])?.toString() ?? '',
        ),
        viewerCount: asInt(pick(m, ['viewerCount', 'viewers', 'peakViewers'])),
      );
    }).where((b) => b.id.isNotEmpty).toList();
  }

  List<UserActivityItem> _parseActivityList(dynamic body) {
    dynamic raw;
    if (body is Map) {
      final map = asJsonMap(body);
      if (map['error'] != null) {
        throw ApiException(map['error'].toString());
      }
      raw = map['activities'] ??
          map['items'] ??
          map['notifications'] ??
          map['data'];
      if (raw is Map) {
        raw = raw['activities'] ?? raw['items'] ?? raw['notifications'];
      }
      final unread = map['unreadCount'] ?? map['unread'];
      if (raw == null && unread != null) return const [];
    } else if (body is List) {
      raw = body;
    }
    if (raw is! List) return const [];
    return raw.map((e) {
      final m = asJsonMap(e);
      return UserActivityItem(
        id: pick(m, ['id', '_id'])?.toString() ?? '',
        title: pick(m, ['title', 'type', 'subject'])?.toString() ?? 'Aktivite',
        body: pick(m, ['body', 'message', 'text', 'description'])?.toString(),
        read: asBool(pick(m, ['read', 'isRead', 'seen'])),
        createdAt: DateTime.tryParse(
          pick(m, ['createdAt', 'created_at', 'timestamp'])?.toString() ?? '',
        ),
        type: pick(m, ['type', 'kind'])?.toString(),
      );
    }).where((a) => a.id.isNotEmpty).toList();
  }
}
