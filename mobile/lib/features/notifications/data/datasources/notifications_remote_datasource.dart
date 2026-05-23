import 'package:dio/dio.dart';

import '../../../../core/network/api_endpoints.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/network/dio_provider.dart';
import '../../../../core/util/json_util.dart';
import '../../domain/entities/app_notification_entity.dart';

class NotificationsRemoteDataSource {
  NotificationsRemoteDataSource(this._dio);

  final Dio _dio;

  Future<List<AppNotificationEntity>> list() async {
    try {
      final res = await _dio.safeGet<dynamic>(ApiEndpoints.notifications);
      final parsed = _parseList(res.data);
      if (parsed != null) return parsed;
    } on ApiException catch (e) {
      if (e.statusCode == 401) {
        throw const ApiException(
          'Bildirimler için oturum açmanız gerekiyor.',
          statusCode: 401,
        );
      }
      rethrow;
    }
    return const [];
  }

  List<AppNotificationEntity>? _parseList(dynamic body) {
    if (body is String) {
      if (body.contains('<!DOCTYPE') || body.contains('<html')) return null;
      return null;
    }
    if (body is! Map && body is! List) return null;

    if (body is Map) {
      final map = asJsonMap(body);
      final err = map['error'] ?? map['message'];
      if (err != null && err.toString().trim().isNotEmpty) return null;

      if (map['success'] == true && map['data'] != null) {
        return _parseList(map['data']);
      }

      final list = pick(map, ['items', 'data', 'notifications', 'results']);
      if (list != null) {
        return asJsonList(list).map(_row).toList();
      }
    }

    if (body is List) {
      return asJsonList(body).map(_row).toList();
    }
    return null;
  }

  AppNotificationEntity _row(Map<String, dynamic> json) {
    return AppNotificationEntity(
      id: pick(json, ['id', '_id'])?.toString() ?? '',
      title: pick(json, ['title', 'subject'])?.toString() ??
          pick(json, ['type'])?.toString() ??
          'Bildirim',
      body: pick(json, ['body', 'message', 'text', 'description']) as String?,
      read: asBool(pick(json, ['read', 'isRead', 'seen'])),
      createdAt: DateTime.tryParse(
        pick(json, ['createdAt', 'created_at', 'timestamp'])?.toString() ?? '',
      ),
      type: pick(json, ['type', 'category'])?.toString(),
      targetPath: pick(json, ['targetPath', 'actionUrl', 'link', 'href'])
          ?.toString(),
      targetId: pick(json, ['targetId', 'entityId', 'refId'])?.toString(),
    );
  }

  Future<void> markRead(String id) async {
    await _dio.safePatch(ApiEndpoints.notificationRead(id), data: const {});
  }
}
