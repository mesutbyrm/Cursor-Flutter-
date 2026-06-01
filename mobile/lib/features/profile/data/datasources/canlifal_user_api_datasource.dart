import 'package:dio/dio.dart';

import '../../../../core/pagination/paged_result.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/network/dio_provider.dart';
import '../../../../core/util/json_util.dart';
import '../../../auth/data/models/user_dto.dart';
import '../../../auth/domain/entities/user_entity.dart';
import '../../domain/entities/profile_stats_entity.dart';

/// canlifal.com Flutter API — lookup, aktivite, yayın geçmişi (site + `/api/users/me/*` yedek).
class CanlifalUserApiDataSource {
  CanlifalUserApiDataSource(this._dio);

  final Dio _dio;

  Future<UserEntity> lookupByUsername(String username) async {
    final name = username.trim();
    if (name.isEmpty) {
      throw const ApiException('Kullanıcı adı gerekli');
    }
    final res = await _dio.safeGet<dynamic>(ApiEndpoints.userLookup(name));
    final body = res.data;
    if (body is Map) {
      final map = asJsonMap(body);
      final err = map['error'];
      if (err != null) throw ApiException(err.toString());
      final userRaw = map['user'] ?? map['data'] ?? map;
      if (userRaw is Map) {
        return UserDto.fromApiMap(asJsonMap(userRaw)).toEntity();
      }
    }
    throw const ApiException('Kullanıcı bulunamadı');
  }

  Future<PagedResult<BroadcastHistoryItemEntity>> broadcastHistory({
    int page = 1,
    int limit = 20,
    String status = 'ended',
  }) async {
    final query = {
      'page': page,
      'limit': limit,
      if (status.isNotEmpty) 'status': status,
    };
    Object? lastError;
    for (final path in [
      ApiEndpoints.userBroadcastHistory,
      ApiEndpoints.meBroadcastHistory,
    ]) {
      try {
        final res = await _dio.safeGet<dynamic>(path, query: query);
        final items = _parseBroadcastHistory(res.data);
        return _asPage(items, page, limit, res.data);
      } catch (e) {
        lastError = e;
      }
    }
    if (lastError != null) throw ApiException.userMessage(lastError);
    return const PagedResult(items: [], hasMore: false);
  }

  Future<PagedResult<ProfileActivityItemEntity>> fetchActivity({
    bool unreadOnly = false,
    int page = 1,
    int limit = 30,
  }) async {
    final query = <String, dynamic>{
      'page': page,
      'limit': limit,
      if (unreadOnly) 'unread': 'true',
    };
    Object? lastError;
    for (final path in [ApiEndpoints.userActivity, ApiEndpoints.meActivity]) {
      try {
        final res = await _dio.safeGet<dynamic>(path, query: query);
        final items = _parseActivityList(res.data);
        return _asPage(items, page, limit, res.data);
      } catch (e) {
        lastError = e;
      }
    }
    if (lastError != null) throw ApiException.userMessage(lastError);
    return const PagedResult(items: [], hasMore: false);
  }

  PagedResult<T> _asPage<T>(List<T> items, int page, int limit, dynamic body) {
    var hasMore = items.length >= limit;
    if (body is Map) {
      final map = asJsonMap(body);
      final data = map['data'];
      final pagRaw = map['pagination'] ??
          (data is Map ? data['pagination'] : null);
      if (pagRaw is Map) {
        final pag = asJsonMap(pagRaw);
        final totalPages = asInt(pag['totalPages']);
        final current = asInt(pag['page']);
        if (totalPages > 0) {
          hasMore = current < totalPages;
        }
      }
    }
    return PagedResult(items: items, hasMore: hasMore);
  }

  Future<void> markAllActivityRead() async {
    const body = {'markAllRead': true};
    final opts = Options(contentType: Headers.jsonContentType);
    Object? lastError;
    for (final path in [ApiEndpoints.userActivity, ApiEndpoints.meActivity]) {
      try {
        await _dio.safePatch<dynamic>(path, data: body, options: opts);
        return;
      } catch (e) {
        lastError = e;
      }
    }
    if (lastError != null) throw ApiException.userMessage(lastError);
  }

  List<BroadcastHistoryItemEntity> _parseBroadcastHistory(dynamic body) {
    dynamic raw;
    if (body is Map) {
      final map = asJsonMap(body);
      if (map['error'] != null) {
        throw ApiException(map['error'].toString());
      }
      final data = map['data'];
      raw = map['items'] ??
          map['broadcasts'] ??
          map['history'] ??
          (data is Map ? data['items'] : null) ??
          (data is List ? data : null);
    } else if (body is List) {
      raw = body;
    }
    if (raw is! List) return const [];
    return raw
        .map((e) => BroadcastHistoryItemEntity.fromJson(asJsonMap(e)))
        .where((b) => b.id.isNotEmpty)
        .toList();
  }

  List<ProfileActivityItemEntity> _parseActivityList(dynamic body) {
    dynamic raw;
    if (body is Map) {
      final map = asJsonMap(body);
      if (map['error'] != null) {
        throw ApiException(map['error'].toString());
      }
      final data = map['data'];
      raw = map['activities'] ??
          map['items'] ??
          map['notifications'] ??
          (data is Map
              ? data['activities'] ?? data['items'] ?? data['notifications']
              : null) ??
          (data is List ? data : null);
    } else if (body is List) {
      raw = body;
    }
    if (raw is! List) return const [];
    return raw
        .map((e) => ProfileActivityItemEntity.fromJson(asJsonMap(e)))
        .where((a) => a.id.isNotEmpty)
        .toList();
  }
}
