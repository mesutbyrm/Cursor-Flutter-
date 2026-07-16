import 'package:dio/dio.dart';

import '../core/network/api_endpoints.dart';
import '../core/network/api_exception.dart';
import '../core/network/dio_provider.dart';
import '../core/sse_client.dart';
import '../core/util/json_util.dart';
import 'service_utils.dart';

/// Bildirim API — kılavuz §9.8 `NotificationRepository`.
class NotificationService {
  NotificationService({
    required Dio Function() resolveAuthedDio,
    SseClient? sseClient,
  })  : _resolveAuthedDio = resolveAuthedDio,
        _sseClient = sseClient;

  final Dio Function() _resolveAuthedDio;
  final SseClient? _sseClient;

  Dio get _dio => _resolveAuthedDio();

  /// `GET /api/notifications`
  Future<List<Map<String, dynamic>>> getNotifications({
    int page = 1,
    int limit = 20,
  }) async {
    final res = await _dio.safeGet<dynamic>(
      ApiEndpoints.notifications,
      query: {'page': page, 'limit': limit},
    );
    return ServiceUtils.extractList(
      res.data,
      keys: const ['notifications', 'items', 'data'],
    );
  }

  /// `POST/PATCH /api/notifications` — okundu işaretle.
  Future<void> markRead(List<String> ids, {bool markAll = false}) async {
    final body = markAll
        ? const {'markAll': true, 'readAll': true}
        : ids.length == 1
            ? {'notificationId': ids.first, 'id': ids.first}
            : {'ids': ids, 'notificationIds': ids};

    try {
      await _dio.safePost<dynamic>(ApiEndpoints.notifications, data: body);
      return;
    } on ApiException catch (e) {
      if (e.statusCode != 404 && e.statusCode != 405) rethrow;
    }
    await _dio.safePatch<dynamic>(ApiEndpoints.notifications, data: body);
  }

  /// `GET /api/notifications/stream` — SSE.
  Stream<SseEvent> connectStream({String? connectionId}) {
    final client = _sseClient;
    if (client == null) {
      throw StateError(
        'SSE için NotificationService oluşturulurken SseClient verilmelidir.',
      );
    }
    return client.notifications(connectionId: connectionId);
  }
}
