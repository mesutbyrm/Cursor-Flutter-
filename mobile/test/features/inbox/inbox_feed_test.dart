import 'package:canlifal_social/features/inbox/domain/inbox_feed_entry.dart';
import 'package:canlifal_social/features/inbox/presentation/inbox_routes.dart';
import 'package:canlifal_social/features/inbox/domain/inbox_tab.dart';
import 'package:canlifal_social/features/inbox/presentation/utils/inbox_notification_visual.dart';
import 'package:canlifal_social/features/messages/domain/entities/message_entities.dart';
import 'package:canlifal_social/features/notifications/domain/entities/app_notification_entity.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('InboxRoutes', () {
    test('pathForTab builds query urls', () {
      expect(InboxRoutes.pathForTab(), '/messages');
      expect(InboxRoutes.pathForTab(InboxTab.system), '/messages?tab=system');
    });
  });

  group('InboxTab', () {
    test('fromQuery parses tab aliases', () {
      expect(InboxTab.fromQuery('system'), InboxTab.system);
      expect(InboxTab.fromQuery('sistem'), InboxTab.system);
      expect(InboxTab.fromQuery('notifications'), InboxTab.system);
      expect(InboxTab.fromQuery('messages'), InboxTab.messages);
      expect(InboxTab.fromQuery(null), InboxTab.all);
    });
  });

  group('mergeInboxFeed', () {
    test('sorts dm and system by newest first', () {
      final conversations = [
        ConversationEntity(
          id: 'u1',
          title: 'Ali',
          lastMessageAt: DateTime(2026, 1, 1, 12),
        ),
      ];
      final notifications = [
        AppNotificationEntity(
          id: 'n1',
          title: 'Kazanç',
          createdAt: DateTime(2026, 1, 2, 10),
          type: 'payment',
        ),
      ];

      final feed = mergeInboxFeed(
        conversations: conversations,
        notifications: notifications,
      );

      expect(feed, hasLength(2));
      expect(feed.first, isA<InboxSystemEntry>());
      expect(feed.last, isA<InboxDmEntry>());
    });
  });

  group('inboxSystemCategoryLabel', () {
    test('maps earnings and live categories', () {
      expect(inboxSystemCategoryLabel('jeton_payment'), 'Kazanç & ödeme');
      expect(inboxSystemCategoryLabel('live_stream_gift'), 'Canlı yayın');
      expect(inboxSystemCategoryLabel('voice_room_pk'), 'Sesli sohbet');
      expect(inboxSystemCategoryLabel('psychic_session'), 'Canlı Falcılar');
    });
  });
}
