import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../inbox/presentation/providers/inbox_unread_providers.dart';
import '../../../messages/presentation/providers/messages_providers.dart';
import '../../../notifications/presentation/providers/notifications_providers.dart';

/// Okunmamış bildirim sayısı — gelen kutusu ile uyumlu.
final unreadNotificationCountProvider = inboxSystemUnreadCountProvider;

/// Okunmamış mesaj toplamı — gelen kutusu ile uyumlu.
final unreadMessagesCountProvider = inboxMessagesUnreadCountProvider;
