import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../messages/presentation/providers/messages_providers.dart';
import '../../../notifications/presentation/providers/notifications_providers.dart';

/// Okunmamış bildirim sayısı (0 ise kırmızı nokta gösterilmez).
final unreadNotificationCountProvider = Provider<int>((ref) {
  final async = ref.watch(notificationsListProvider);
  return async.maybeWhen(
    data: (list) => list.where((e) => !e.read).length,
    orElse: () => 0,
  );
});

/// Okunmamış mesaj (konuşma) toplamı.
final unreadMessagesCountProvider = Provider<int>((ref) {
  final async = ref.watch(conversationsProvider);
  return async.maybeWhen(
    data: (list) => list.fold<int>(0, (a, c) => a + c.unreadCount),
    orElse: () => 0,
  );
});
