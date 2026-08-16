import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../membership/presentation/controllers/membership_controller.dart';
import '../../../profile/presentation/premium_2026/profile_membership_helpers.dart';
import '../../../profile/presentation/providers/profile_hub_providers.dart';
import '../../../profile/presentation/providers/profile_providers.dart';

/// Jeton / CFC mağazasında üyelik planı teaser — bekleyen ödeme yoksa gösterilir.
class MembershipStoreTeaserBanner extends ConsumerWidget {
  const MembershipStoreTeaserBanner({
    super.key,
    required this.store,
    this.padding = const EdgeInsets.only(bottom: 12),
  });

  final MembershipStoreKind store;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final info = ref.watch(profileMembershipInfoProvider);
    if (info.hasActiveSubscription) return const SizedBox.shrink();

    final ui = ref.watch(membershipControllerProvider);
    final catalogTier = catalogTierForMembership(info, ui.tiers);
    final expiresAt =
        ref.watch(walletBalancesProvider).valueOrNull?.membershipExpiresAt;
    final bannerTitle = buildMembershipStoreTeaserBannerTitle(
      info: info,
      expiresAt: expiresAt,
    );
    final subtitle = buildMembershipStoreTeaserSubtitle(
      info: info,
      store: store,
      tiers: ui.tiers,
      packages: ui.apiPackages,
      catalogTier: catalogTier,
      expiresAt: expiresAt,
    );
    final actionLabel = buildMembershipStoreTeaserBannerActionLabel(info: info);

    return Padding(
      padding: padding,
      child: Material(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: () => context.push('/premium-membership'),
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                Icon(
                  info.isExpired
                      ? Icons.history_rounded
                      : Icons.workspace_premium_rounded,
                  color: info.isExpired
                      ? Colors.white54
                      : const Color(0xFFFFD54F),
                  size: 22,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        bannerTitle,
                        style: const TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 11.5,
                          height: 1.35,
                          color: Colors.white.withValues(alpha: 0.62),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  actionLabel,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.55),
                    fontWeight: FontWeight.w800,
                    fontSize: 11,
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  color: Colors.white.withValues(alpha: 0.45),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
