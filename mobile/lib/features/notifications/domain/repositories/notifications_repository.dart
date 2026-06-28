import '../entities/app_notification_entity.dart';

abstract class NotificationsRepository {
  Future<List<AppNotificationEntity>> fetch({bool forceRefresh = false});
  Future<void> markRead(String id);
  Future<void> clearPaymentNotifications();

  /// canlifal.com `PATCH /api/user/activity` — `markAllRead: true`
  Future<void> markAllRead();
}
