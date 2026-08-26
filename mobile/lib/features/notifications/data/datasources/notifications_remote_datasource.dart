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
      if (parsed != null) return _dedupeNotifications(parsed);
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
      targetPath: pick(json, [
        'targetPath',
        'actionUrl',
        'link',
        'href',
        'deepLink',
        'deeplink',
      ])?.toString(),
      targetId: pick(json, [
        'targetId',
        'entityId',
        'refId',
        'referenceId',
        'sessionId',
        'session_id',
        'conversationId',
      ])?.toString(),
      imageUrl: pick(json, [
        'imageUrl',
        'image',
        'avatar',
        'avatarUrl',
        'iconUrl',
        'thumbnail',
      ])?.toString(),
      senderId: pick(json, [
        'senderId',
        'userId',
        'actorId',
        'fromUserId',
      ])?.toString(),
    );
  }

  Future<int?> fetchUnreadCount() async {
    try {
      final res = await _dio.safeGet<dynamic>(ApiEndpoints.notificationsUnread);
      final map = asJsonMap(res.data);
      final data = map['data'] is Map ? asJsonMap(map['data']) : map;
      final countRaw = pick(data, ['count', 'unread', 'unreadCount']);
      if (countRaw != null) return asInt(countRaw);
    } catch (_) {}
    return null;
  }

  Future<void> markRead(String id) async {
    try {
      await _dio.safePatch<dynamic>(
        ApiEndpoints.notifications,
        data: {'notificationId': id},
      );
      return;
    } catch (_) {}
    try {
      await _dio.safePatch<dynamic>(
        ApiEndpoints.notifications,
        data: {'id': id, 'read': true},
      );
      return;
    } catch (_) {}
    await _dio.safePatch(ApiEndpoints.notificationRead(id), data: const {});
  }

  Future<void> markAllRead() async {
    Object? lastError;
    const bodies = [
      {'markAll': true},
      {'readAll': true},
      {'markAllRead': true},
    ];
    for (final body in bodies) {
      try {
        await _dio.safePatch<dynamic>(ApiEndpoints.notifications, data: body);
        return;
      } catch (e) {
        lastError = e;
      }
    }
    for (final body in bodies) {
      try {
        await _dio.safePost<dynamic>(ApiEndpoints.notifications, data: body);
        return;
      } catch (e) {
        lastError = e;
      }
    }
    if (lastError is ApiException) throw lastError;
    throw ApiException(
      ApiException.userMessage(lastError ?? 'Bildirimler okundu işaretlenemedi'),
    );
  }

  Future<void> clearPaymentNotifications() async {
    await _dio.safeDelete(ApiEndpoints.notificationsPaymentClear);
  }

  List<AppNotificationEntity> _dedupeNotifications(
    List<AppNotificationEntity> items,
  ) {
    final seenIds = <String>{};
    final seenFingerprints = <String>{};
    final out = <AppNotificationEntity>[];
    for (final item in items) {
      final id = item.id.trim();
      if (id.isNotEmpty && !seenIds.add(id)) continue;
      final fingerprint = [
        item.type?.toLowerCase() ?? '',
        item.title.trim().toLowerCase(),
        item.body?.trim().toLowerCase() ?? '',
        item.targetId?.trim() ?? '',
      ].join('|');
      if (fingerprint.isNotEmpty && !seenFingerprints.add(fingerprint)) {
        continue;
      }
      out.add(item);
    }
    return out;
  }
}
