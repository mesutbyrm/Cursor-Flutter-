import '../../messages/domain/entities/message_entities.dart';
import '../../notifications/domain/entities/app_notification_entity.dart';

/// Birleşik gelen kutusu satırı — DM veya sistem bildirimi.
sealed class InboxFeedEntry {
  const InboxFeedEntry();

  DateTime get sortTime;

  bool get isUnread;
}

final class InboxDmEntry extends InboxFeedEntry {
  const InboxDmEntry(this.conversation);

  final ConversationEntity conversation;

  @override
  DateTime get sortTime =>
      conversation.lastMessageAt ?? DateTime.fromMillisecondsSinceEpoch(0);

  @override
  bool get isUnread => conversation.unreadCount > 0;
}

final class InboxSystemEntry extends InboxFeedEntry {
  const InboxSystemEntry(this.notification);

  final AppNotificationEntity notification;

  @override
  DateTime get sortTime =>
      notification.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);

  @override
  bool get isUnread => !notification.read;
}

List<InboxFeedEntry> mergeInboxFeed({
  required List<ConversationEntity> conversations,
  required List<AppNotificationEntity> notifications,
}) {
  final out = <InboxFeedEntry>[
    for (final c in conversations) InboxDmEntry(c),
    for (final n in notifications) InboxSystemEntry(n),
  ]..sort((a, b) => b.sortTime.compareTo(a.sortTime));
  return out;
}
