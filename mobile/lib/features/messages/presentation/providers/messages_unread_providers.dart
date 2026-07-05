import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'conversations_list_notifier.dart';
import 'messages_providers.dart';

/// Okunmamış toplam — tam liste üzerinden (lazy görünümden bağımsız).
final conversationsUnreadTotalProvider = Provider<int>((ref) {
  return ref.watch(conversationsListNotifierProvider).maybeWhen(
        data: (s) => s.all.fold<int>(0, (sum, c) => sum + c.unreadCount),
        orElse: () => ref.watch(conversationsProvider).maybeWhen(
              data: (items) =>
                  items.fold<int>(0, (sum, c) => sum + c.unreadCount),
              orElse: () => 0,
            ),
      );
});

/// Tüm sohbetlerdeki okunmamış mesaj toplamı (alt bar rozeti).
final messagesUnreadCountProvider = conversationsUnreadTotalProvider;
