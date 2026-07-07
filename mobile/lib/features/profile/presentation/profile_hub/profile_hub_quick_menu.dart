import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../notifications/presentation/providers/notifications_providers.dart';
import '../premium_2026/profile_theme.dart';
import '../premium_2026/widgets/profile_action_tile.dart';
import '../providers/profile_hub_providers.dart';

/// Hızlı menü — cüzdan, jeton geçmişi, hediye, bildirim, ziyaretçi, saklananlar.
class ProfileHubQuickMenu extends ConsumerWidget {
  const ProfileHubQuickMenu({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unread = ref.watch(notificationsUnreadCountProvider);
    final visitors = ref.watch(profileVisitorBadgeProvider);

    final items = <({IconData icon, String label, VoidCallback onTap, int? badge})>[
      (
        icon: Icons.account_balance_wallet_rounded,
        label: 'Cüzdanım',
        onTap: () => context.push('/wallet'),
        badge: null,
      ),
      (
        icon: Icons.history_rounded,
        label: 'Jeton Geçmişim',
        onTap: () => context.push('/profile/transactions'),
        badge: null,
      ),
      (
        icon: Icons.card_giftcard_rounded,
        label: 'Hediye Geçmişim',
        onTap: () => context.push('/gifts/history'),
        badge: null,
      ),
      (
        icon: Icons.notifications_rounded,
        label: 'Bildirimlerim',
        onTap: () => context.push('/notifications'),
        badge: unread > 0 ? unread : null,
      ),
      (
        icon: Icons.people_outline_rounded,
        label: 'Ziyaretçilerim',
        onTap: () => context.push('/profile/visitors'),
        badge: visitors > 0 ? visitors : null,
      ),
      (
        icon: Icons.bookmark_rounded,
        label: 'Sakladıklarım',
        onTap: () => context.push('/favorites'),
        badge: null,
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        const spacing = 10.0;
        final tileW = (constraints.maxWidth - spacing * 5) / 6;
        return Row(
          children: [
            for (var i = 0; i < items.length; i++) ...[
              if (i > 0) const SizedBox(width: spacing),
              SizedBox(
                width: tileW,
                child: ProfileActionTile(
                  icon: items[i].icon,
                  label: items[i].label,
                  onTap: items[i].onTap,
                  badge: items[i].badge,
                  gradient: [
                    ProfilePremiumTheme.neonPurple.withValues(alpha: 0.25),
                    ProfilePremiumTheme.deepBg,
                  ],
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}
