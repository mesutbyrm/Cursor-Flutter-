import 'package:dio/dio.dart';

import '../../../../core/network/api_endpoints.dart';
import '../../../../core/network/dio_provider.dart';
import '../../../../core/util/json_util.dart';
import '../../domain/entities/app_notification_entity.dart';

class NotificationsRemoteDataSource {
  NotificationsRemoteDataSource(this._dio);

  final Dio _dio;

  Future<List<AppNotificationEntity>> list() async {
    final res = await _dio.safeGet<dynamic>(ApiEndpoints.notifications);
    final body = res.data;
    dynamic list;
    if (body is Map<String, dynamic>) {
      list = pick(body, ['items', 'data', 'notifications', 'results']);
    } else {
      list = body;
    }
    return asJsonList(list).map(_row).toList();
  }

  AppNotificationEntity _row(Map<String, dynamic> json) {
    return AppNotificationEntity(
      id: pick(json, ['id', '_id'])?.toString() ?? '',
      title: pick(json, ['title', 'type', 'subject'])?.toString() ?? 'Bildirim',
      body: pick(json, ['body', 'message', 'text', 'description']) as String?,
      read: asBool(pick(json, ['read', 'isRead', 'seen'])),
      createdAt: DateTime.tryParse(
        pick(json, ['createdAt', 'created_at', 'timestamp'])?.toString() ?? '',
      ),
    );
  }

  Future<void> markRead(String id) async {
    await _dio.safePatch(ApiEndpoints.notificationRead(id), data: const {});
  }
}
