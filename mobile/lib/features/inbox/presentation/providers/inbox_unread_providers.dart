import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../messages/presentation/providers/messages_unread_providers.dart';
import '../../../notifications/presentation/providers/notifications_providers.dart';

/// TikTok tarzı tek rozet — DM + sistem bildirimleri toplamı.
final inboxUnreadCountProvider = Provider<int>((ref) {
  final messages = ref.watch(messagesUnreadCountProvider);
  final notifications = ref.watch(notificationsUnreadCountProvider);
  return messages + notifications;
});

final inboxSystemUnreadCountProvider = notificationsUnreadCountProvider;

final inboxMessagesUnreadCountProvider = messagesUnreadCountProvider;
