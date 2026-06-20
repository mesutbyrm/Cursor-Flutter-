import 'package:dio/dio.dart';

import '../../../../core/network/api_endpoints.dart';
import '../../../../core/network/dio_provider.dart';
import '../../../../core/util/json_util.dart';
import '../../domain/entities/live_fortune_request_entity.dart';

/// Canlı yayın fal istekleri — üretim `/api/video-streams/{id}/fortune-requests`.
class LiveFortuneRequestDataSource {
  LiveFortuneRequestDataSource(this._dio);

  final Dio _dio;

  Future<List<LiveFortuneRequestEntity>> fetchRequests(String streamId) async {
    final id = streamId.trim();
    if (id.isEmpty) return const [];

    try {
      final res = await _dio.safeGet<dynamic>(
        ApiEndpoints.videoStreamFortuneRequests(id),
      );
      return _parseList(res.data);
    } catch (_) {
      try {
        final res = await _dio.safeGet<dynamic>(
          ApiEndpoints.liveFalRequests,
          query: {'streamId': id},
        );
        return _parseList(res.data);
      } catch (_) {
        return const [];
      }
    }
  }

  Future<LiveFortuneRequestEntity> createRequest({
    required String streamId,
    required String displayName,
    required String question,
    required String fortuneType,
    required LiveFortunePriority priority,
  }) async {
    final body = {
      'displayName': displayName.trim(),
      'question': question.trim(),
      'fortuneType': fortuneType,
      'type': fortuneType,
      'priority': priority.name,
      'jetonCost': priority.jetonCost,
    };

    try {
      final res = await _dio.safePost<dynamic>(
        ApiEndpoints.videoStreamFortuneRequests(streamId.trim()),
        data: body,
      );
      final row = _unwrap(res.data);
      if (row != null) return LiveFortuneRequestEntity.fromJson(row);
    } catch (_) {}

    final res = await _dio.safePost<dynamic>(
      ApiEndpoints.liveFalRequestCreate,
      data: {...body, 'streamId': streamId.trim()},
    );
    final row = _unwrap(res.data);
    if (row == null) {
      throw DioException(
        requestOptions: RequestOptions(path: ApiEndpoints.liveFalRequestCreate),
        message: 'Fal isteği oluşturulamadı',
      );
    }
    return LiveFortuneRequestEntity.fromJson(row);
  }

  Future<LiveFortuneRequestEntity> updateStatus({
    required String streamId,
    required String requestId,
    required LiveFortuneRequestStatus status,
  }) async {
    final body = {'status': status.name};

    try {
      final res = await _dio.safePatch<dynamic>(
        ApiEndpoints.videoStreamFortuneRequest(streamId.trim(), requestId),
        data: body,
      );
      final row = _unwrap(res.data);
      if (row != null) return LiveFortuneRequestEntity.fromJson(row);
    } catch (_) {}

    final res = await _dio.safePost<dynamic>(
      ApiEndpoints.liveFalRequestUpdate(requestId),
      data: {...body, 'streamId': streamId.trim()},
    );
    final row = _unwrap(res.data);
    if (row == null) {
      throw DioException(
        requestOptions: RequestOptions(path: ApiEndpoints.liveFalRequestUpdate(requestId)),
        message: 'Durum güncellenemedi',
      );
    }
    return LiveFortuneRequestEntity.fromJson(row);
  }

  Future<void> completeRequest({
    required String streamId,
    required String requestId,
  }) async {
    try {
      await _dio.safePost<dynamic>(
        ApiEndpoints.liveFalRequestComplete(requestId),
        data: {'streamId': streamId.trim()},
      );
      return;
    } catch (_) {}

    await updateStatus(
      streamId: streamId,
      requestId: requestId,
      status: LiveFortuneRequestStatus.answered,
    );
  }

  List<LiveFortuneRequestEntity> _parseList(dynamic body) {
    dynamic list;
    if (body is Map) {
      list = pick(Map<String, dynamic>.from(body), [
        'requests',
        'items',
        'data',
        'fortuneRequests',
      ]);
    } else {
      list = body;
    }
    if (list is! List) return const [];
    return list
        .whereType<Map>()
        .map((e) => LiveFortuneRequestEntity.fromJson(
              Map<String, dynamic>.from(e),
            ))
        .where((r) => r.id.isNotEmpty)
        .toList();
  }

  Map<String, dynamic>? _unwrap(dynamic body) {
    if (body is! Map) return null;
    final map = Map<String, dynamic>.from(body);
    final data = map['data'];
    if (data is Map) {
      final inner = Map<String, dynamic>.from(data);
      if (inner['request'] is Map) {
        return Map<String, dynamic>.from(inner['request'] as Map);
      }
      return inner;
    }
    if (map['request'] is Map) {
      return Map<String, dynamic>.from(map['request'] as Map);
    }
    return map.containsKey('id') ? map : null;
  }
}
