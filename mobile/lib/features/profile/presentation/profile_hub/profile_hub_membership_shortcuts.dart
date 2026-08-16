import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../membership/presentation/controllers/membership_controller.dart';
import '../premium_2026/profile_membership_helpers.dart';
import '../premium_2026/profile_theme.dart';
import '../providers/profile_hub_providers.dart';
import '../providers/profile_providers.dart';
import '../widgets/premium/profile_glass.dart';

/// Üyelik kısayolları — planlar, VIP gold, kozmetik.
class ProfileHubMembershipShortcuts extends ConsumerWidget {
  const ProfileHubMembershipShortcuts({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final info = ref.watch(profileMembershipInfoProvider);
    final ui = ref.watch(membershipControllerProvider);
    final catalogTier = catalogTierForMembership(info, ui.tiers);
    final expiresAt =
        ref.watch(walletBalancesProvider).valueOrNull?.membershipExpiresAt;
    final planHint = buildMembershipWalletHubSubtitle(
      info: info,
      tiers: ui.tiers,
      packages: ui.apiPackages,
      catalogTier: catalogTier,
      daysRemaining: info.daysRemaining,
      expiresAt: expiresAt,
    );
    final vipHint = buildVipGoldShortcutSubtitle(info);

    return Row(
      children: [
        Expanded(
          child: _ShortcutChip(
            icon: Icons.workspace_premium_outlined,
            label: info.hasPaidTier ? 'Planı Yönet' : 'Planlar',
            subtitle: planHint,
            highlight: info.hasPaidTier,
            onTap: () => context.push('/premium-membership'),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _ShortcutChip(
            icon: Icons.diamond_outlined,
            label: 'VIP Gold',
            subtitle: vipHint,
            highlight: info.isVip,
            onTap: () => context.push('/vip-gold'),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _ShortcutChip(
            icon: Icons.auto_awesome_outlined,
            label: 'Kozmetik',
            onTap: () => context.push('/profile/cosmetics'),
          ),
        ),
      ],
    );
  }
}

class _ShortcutChip extends StatelessWidget {
  const _ShortcutChip({
    required this.icon,
    required this.label,
    required this.onTap,
    this.subtitle,
    this.highlight = false,
  });

  final IconData icon;
  final String label;
  final String? subtitle;
  final VoidCallback onTap;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    return ProfileGlass(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      borderRadius: ProfilePremiumTheme.radiusSm,
      borderColor: highlight
          ? ProfilePremiumTheme.neonPurple.withValues(alpha: 0.55)
          : ProfilePremiumTheme.glassBorder,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 20,
              color: highlight
                  ? ProfilePremiumTheme.neonPurple
                  : Colors.white70,
            ),
            const SizedBox(height: 6),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white.withValues(alpha: highlight ? 0.95 : 0.75),
                fontSize: 10,
                fontWeight: FontWeight.w800,
              ),
            ),
            if (subtitle != null && subtitle!.trim().isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                subtitle!,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: highlight ? 0.7 : 0.5),
                  fontSize: 8,
                  fontWeight: FontWeight.w600,
                  height: 1.2,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
