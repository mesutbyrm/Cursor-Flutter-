import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../membership/presentation/controllers/membership_controller.dart';
import '../profile_membership_helpers.dart';
import '../../providers/profile_hub_providers.dart';
import '../../providers/profile_providers.dart';

/// Üyelik planı özeti — profil düzenleme ve ayarlar için.
class ProfileMembershipManageTile extends ConsumerWidget {
  const ProfileMembershipManageTile({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final info = ref.watch(profileMembershipInfoProvider);
    final ui = ref.watch(membershipControllerProvider);
    final catalogTier = catalogTierForMembership(info, ui.tiers);
    final expiresAt =
        ref.watch(walletBalancesProvider).valueOrNull?.membershipExpiresAt;

    final leadingAccent = resolveMembershipManageTileLeadingAccent(info: info);
    final leadingColor = switch (leadingAccent) {
      MembershipManageTileLeadingAccent.paid => Colors.amber,
      MembershipManageTileLeadingAccent.expired => Colors.orangeAccent,
      MembershipManageTileLeadingAccent.standard => Colors.white54,
    };

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => context.push('/premium-membership'),
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            children: [
              Icon(
                Icons.workspace_premium_outlined,
                color: leadingColor,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      buildMembershipHubSectionTitle(
                        info: info,
                        expiresAt: expiresAt,
                      ),
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      buildMembershipSettingsManageSubtitle(
                        info: info,
                        tiers: ui.tiers,
                        packages: ui.apiPackages,
                        catalogTier: catalogTier,
                        daysRemaining: info.daysRemaining,
                        expiresAt: expiresAt,
                      ),
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.6),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded),
            ],
          ),
        ),
      ),
    );
  }
}
