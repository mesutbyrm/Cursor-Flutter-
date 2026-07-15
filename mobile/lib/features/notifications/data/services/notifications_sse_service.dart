import 'dart:async';

import '../../../../core/network/api_endpoints.dart';
import '../../../../core/network/sse/base_sse_service.dart';
import '../../../../core/util/json_util.dart';
import '../../domain/entities/app_notification_entity.dart';

/// Bildirim SSE — kılavuz: `GET /api/notifications/stream`.
class NotificationsSseService extends BaseSseService {
  NotificationsSseService()
      : _events = StreamController<AppNotificationEntity>.broadcast();

  final StreamController<AppNotificationEntity> _events;

  Stream<AppNotificationEntity> get events => _events.stream;

  @override
  String streamPath() => ApiEndpoints.notificationsStream;

  @override
  void onSseBlock(String block) {
    final map = BaseSseService.parseSseJsonBlock(block);
    if (map == null) return;
    final type = (map['type'] ?? '').toString().toLowerCase();
    if (type == 'connected' || type == 'ping' || type == 'heartbeat') return;

    final notification = _parseNotification(map);
    if (notification == null || notification.id.isEmpty) return;
    if (!_events.isClosed) _events.add(notification);
  }

  AppNotificationEntity? _parseNotification(Map<String, dynamic> map) {
    final nested = map['notification'] ?? map['data'] ?? map['payload'];
    if (nested is Map) {
      return NotificationsSseService.parseRow(Map<String, dynamic>.from(nested));
    }
    if (typeLooksLikeNotification(map)) {
      return NotificationsSseService.parseRow(map);
    }
    return null;
  }

  static bool typeLooksLikeNotification(Map<String, dynamic> map) {
    final type = (map['type'] ?? '').toString().toLowerCase();
    if (type == 'notification') return true;
    return map.containsKey('title') ||
        map.containsKey('subject') ||
        map.containsKey('body');
  }

  /// REST ve SSE ortak parse — web JSON alanlarıyla uyumlu.
  static AppNotificationEntity parseRow(Map<String, dynamic> json) {
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
      targetId: pick(json, [
        'targetId',
        'entityId',
        'refId',
        'sessionId',
        'session_id',
      ])?.toString(),
    );
  }

  @override
  void dispose() {
    unawaited(disconnect());
    _events.close();
    super.dispose();
  }
}
