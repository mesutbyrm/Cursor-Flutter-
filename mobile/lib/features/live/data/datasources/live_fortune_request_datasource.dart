import 'package:dio/dio.dart';

import '../../../../core/network/api_endpoints.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/network/dio_provider.dart';
import '../../../../core/network/live_debug_log.dart';
import '../../../../core/util/json_util.dart';
import '../../domain/entities/live_fortune_request_entity.dart';

/// Canlı yayın fal istekleri — üretim `/api/video-streams/{id}/fortune-requests`.
class LiveFortuneRequestDataSource {
  LiveFortuneRequestDataSource(this._dio);

  final Dio _dio;

  static const _defaultTypeId = 'tek-soru';

  /// Eski UI slug → üretim `typeId` (katalog `GET /api/fortune-request-types`).
  static String resolveTypeId(String fortuneType) {
    final raw = fortuneType.trim();
    if (raw.isEmpty) return _defaultTypeId;
    final lower = raw.toLowerCase();
    return switch (lower) {
      'tarot' || 'coffee' || 'astrology' || 'palmistry' || 'numerology' =>
        _defaultTypeId,
      'evet-hayir' || 'evet_hayir' => 'evet-hayır',
      'detayli-fal' || 'detayli_fal' => 'detaylı-fal',
      _ => raw.contains('-') || raw.contains('ı') || raw.contains('ş')
          ? raw
          : _defaultTypeId,
    };
  }

  Future<List<LiveFortuneRequestEntity>> fetchRequests(String streamId) async {
    final id = streamId.trim();
    if (id.isEmpty) return const [];

    Object? lastError;
    try {
      final res = await _dio.safeGet<dynamic>(
        ApiEndpoints.videoStreamFortuneRequests(id),
      );
      return _parseList(res.data);
    } catch (e) {
      lastError = e;
      LiveDebugLog.log('fal.request.fetch.fail', {
        'streamId': id,
        'primary': ApiEndpoints.videoStreamFortuneRequests(id),
        'error': ApiException.userMessage(e),
      });
    }

    try {
      final res = await _dio.safeGet<dynamic>(
        ApiEndpoints.liveFalRequests,
        query: {'streamId': id},
      );
      return _parseList(res.data);
    } catch (e) {
      lastError = e;
      LiveDebugLog.log('fal.request.fetch.fallback.fail', {
        'streamId': id,
        'error': ApiException.userMessage(e),
      });
    }

    if (lastError is ApiException) throw lastError;
    throw ApiException(ApiException.userMessage(lastError));
  }

  Future<LiveFortuneRequestEntity> createRequest({
    required String streamId,
    required String displayName,
    required String question,
    required String fortuneType,
    required LiveFortunePriority priority,
    int? jetonCost,
  }) async {
    final id = streamId.trim();
    final typeId = resolveTypeId(fortuneType);
    final productionBody = {
      'typeId': typeId,
      'question': question.trim(),
      'isHidden': false,
      'nickname': displayName.trim(),
    };

    final primaryPath = ApiEndpoints.videoStreamFortuneRequests(id);
    LiveDebugLog.log('fal.request.create', {
      'streamId': id,
      'path': primaryPath,
      'typeId': typeId,
      'priority': priority.name,
    });

    try {
      final res = await _dio.safePost<dynamic>(
        primaryPath,
        data: productionBody,
      );
      LiveDebugLog.log('fal.request.create.ok', {
        'streamId': id,
        'status': res.statusCode,
        'path': primaryPath,
      });
      final row = _unwrap(res.data);
      if (row != null) return LiveFortuneRequestEntity.fromJson(row);
      throw DioException(
        requestOptions: RequestOptions(path: primaryPath),
        message: 'Fal isteği oluşturulamadı',
      );
    } on DioException catch (e) {
      LiveDebugLog.log('fal.request.create.fail', {
        'streamId': id,
        'path': primaryPath,
        'status': e.response?.statusCode,
        'error': ApiException.userMessage(e),
      });
      rethrow;
    }
  }

  Future<LiveFortuneRequestEntity> updateStatus({
    required String streamId,
    required String requestId,
    required LiveFortuneRequestStatus status,
  }) async {
    final action = _productionAction(status);
    if (action != null) {
      try {
        final res = await _dio.safePatch<dynamic>(
          ApiEndpoints.videoStreamFortuneRequests(streamId.trim()),
          data: {'action': action, 'requestId': requestId},
        );
        final row = _unwrap(res.data);
        if (row != null) return LiveFortuneRequestEntity.fromJson(row);
        return LiveFortuneRequestEntity(
          id: requestId,
          streamId: streamId,
          userId: '',
          displayName: '',
          question: '',
          fortuneType: _defaultTypeId,
          priority: LiveFortunePriority.standard,
          status: status,
          jetonCost: 0,
          createdAt: DateTime.now(),
        );
      } catch (e) {
        LiveDebugLog.log('fal.request.update.production.fail', {
          'requestId': requestId,
          'action': action,
          'error': ApiException.userMessage(e),
        });
      }
    }

    final body = {'status': status.name};
    try {
      final res = await _dio.safePatch<dynamic>(
        ApiEndpoints.videoStreamFortuneRequest(streamId.trim(), requestId),
        data: body,
      );
      final row = _unwrap(res.data);
      if (row != null) return LiveFortuneRequestEntity.fromJson(row);
    } catch (e) {
      LiveDebugLog.log('fal.request.update.fail', {
        'requestId': requestId,
        'error': ApiException.userMessage(e),
      });
    }

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

  Future<Map<String, dynamic>?> fetchMyStatus(String streamId) async {
    final id = streamId.trim();
    if (id.isEmpty) return null;
    try {
      final res = await _dio.safeGet<dynamic>(
        ApiEndpoints.videoStreamFortuneMyStatus(id),
      );
      final body = res.data;
      if (body is Map) return Map<String, dynamic>.from(body);
      return null;
    } on ApiException catch (e) {
      // Aktif istek yok.
      if (e.statusCode == 404) return null;
      LiveDebugLog.log('fal.request.myStatus.fail', {
        'streamId': id,
        'error': e.message,
      });
      rethrow;
    }
  }

  String? _productionAction(LiveFortuneRequestStatus status) => switch (status) {
        LiveFortuneRequestStatus.reviewing => 'select',
        LiveFortuneRequestStatus.answered => 'complete',
        LiveFortuneRequestStatus.cancelled => 'refund',
        _ => null,
      };

  List<LiveFortuneRequestEntity> _parseList(dynamic body) {
    if (body is List) {
      return body
          .whereType<Map>()
          .map((e) => LiveFortuneRequestEntity.fromJson(
                Map<String, dynamic>.from(e),
              ))
          .where((r) => r.id.isNotEmpty)
          .toList();
    }
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
