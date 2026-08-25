import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../inbox/presentation/inbox_routes.dart';
import '../../../inbox/presentation/providers/inbox_unread_providers.dart';
import '../premium_2026/profile_theme.dart';
import '../premium_2026/profile_membership_helpers.dart';
import '../premium_2026/widgets/profile_action_tile.dart';
import '../providers/profile_hub_providers.dart';

/// Hızlı menü — cüzdan, üyelik, jeton geçmişi, hediye, bildirim, ziyaretçi, saklananlar.
class ProfileHubQuickMenu extends ConsumerWidget {
  const ProfileHubQuickMenu({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unread = ref.watch(inboxUnreadCountProvider);
    final visitors = ref.watch(profileVisitorBadgeProvider);
    final membershipInfo = ref.watch(profileMembershipInfoProvider);
    final membershipLabel = buildMembershipQuickMenuLabel(info: membershipInfo);

    final items = <({IconData icon, String label, VoidCallback onTap, int? badge})>[
      (
        icon: Icons.account_balance_wallet_rounded,
        label: 'Cüzdanım',
        onTap: () => context.push('/wallet'),
        badge: null,
      ),
      (
        icon: Icons.workspace_premium_rounded,
        label: membershipLabel,
        onTap: () => context.push('/premium-membership'),
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
        icon: Icons.inbox_rounded,
        label: 'Gelen Kutusu',
        onTap: () => InboxRoutes.open(context),
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

    return SizedBox(
      height: 78,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: items.length,
        separatorBuilder: (_, _) => const SizedBox(width: 10),
        itemBuilder: (context, i) {
          final item = items[i];
          return SizedBox(
            width: 72,
            child: ProfileActionTile(
              icon: item.icon,
              label: item.label,
              onTap: item.onTap,
              badge: item.badge,
              gradient: [
                ProfilePremiumTheme.neonPurple.withValues(alpha: 0.25),
                ProfilePremiumTheme.deepBg,
              ],
            ),
          );
        },
      ),
    );
  }
}
