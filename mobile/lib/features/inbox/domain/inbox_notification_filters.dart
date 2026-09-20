import '../../notifications/domain/entities/app_notification_entity.dart';

/// Sistem sekmesinde gösterilmeyecek — DM/ sohbet bildirimleri (konuşma listesinde).
bool isDirectMessageNotification(AppNotificationEntity n) {
  final t = (n.type ?? '').toLowerCase().trim();
  if (t.contains('message') ||
      t.contains('chat') ||
      t == 'dm' ||
      t.contains('direct_message')) {
    return true;
  }
  final path = (n.targetPath ?? '').toLowerCase();
  if (path.contains('/chat/') ||
      path.startsWith('/messages') ||
      path.contains('conversation')) {
    return true;
  }
  if ((n.senderId ?? '').trim().isNotEmpty &&
      (t.isEmpty || t == 'notification')) {
    return false;
  }
  return false;
}

bool isPlatformSystemNotification(AppNotificationEntity n) =>
    !isDirectMessageNotification(n);

List<AppNotificationEntity> filterSystemNotifications(
  Iterable<AppNotificationEntity> items,
) =>
    items.where(isPlatformSystemNotification).toList();
