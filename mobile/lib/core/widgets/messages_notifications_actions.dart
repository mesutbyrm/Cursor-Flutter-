import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/inbox/presentation/providers/inbox_unread_providers.dart';

import '../ui/premium/premium_icon_button.dart';

/// Üst bar — birleşik gelen kutusu (mesaj + sistem bildirimi). TikTok tarzı tek giriş.
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
    final unreadInbox = ref.watch(inboxUnreadCountProvider);

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
          icon: Icons.inbox_rounded,
          size: iconSize,
          showBadge: unreadInbox > 0,
          badgeCount: unreadInbox,
          onTap: () => context.push('/messages'),
        ),
      ],
    );
  }
}
