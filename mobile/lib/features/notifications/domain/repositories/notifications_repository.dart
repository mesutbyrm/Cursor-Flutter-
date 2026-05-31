import '../entities/app_notification_entity.dart';

abstract class NotificationsRepository {
  Future<List<AppNotificationEntity>> fetch();
  Future<void> markRead(String id);

  /// canlifal.com `PATCH /api/user/activity` — `markAllRead: true`
  Future<void> markAllRead();
}
