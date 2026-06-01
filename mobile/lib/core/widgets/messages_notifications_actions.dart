import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../ui/premium/premium_icon_button.dart';
import '../../features/messages/presentation/providers/messages_providers.dart';
import '../../features/notifications/presentation/providers/notifications_providers.dart';

/// Üst bar — mesajlar (rozet) + bildirimler (rozet). Tüm ana sekmelerde ortak.
class MessagesNotificationsActions extends ConsumerWidget {
  const MessagesNotificationsActions({
    super.key,
    this.iconSize = 40,
    this.spacing = 6,
  });

  final double iconSize;
  final double spacing;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unreadMessages = ref.watch(messagesUnreadCountProvider);
    final unreadNotifications = ref.watch(notificationsUnreadCountProvider);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        PremiumIconButton(
          icon: Icons.search_rounded,
          size: iconSize,
          onTap: () => context.push('/search'),
        ),
        SizedBox(width: spacing),
        PremiumIconButton(
          icon: Icons.chat_bubble_outline_rounded,
          size: iconSize,
          showBadge: unreadMessages > 0,
          badgeCount: unreadMessages,
          onTap: () => context.push('/messages'),
        ),
        SizedBox(width: spacing),
        PremiumIconButton(
          icon: Icons.notifications_none_rounded,
          size: iconSize,
          showBadge: unreadNotifications > 0,
          badgeCount: unreadNotifications,
          onTap: () => context.push('/notifications'),
        ),
      ],
    );
  }
}
