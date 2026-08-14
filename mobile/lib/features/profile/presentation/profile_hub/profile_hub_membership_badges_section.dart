import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/images/canlifal_network_image.dart';
import '../../../../core/ui/premium/premium_skeleton.dart';
import '../../../cosmetics/domain/cosmetic_item.dart';
import '../../../cosmetics/presentation/providers/cosmetics_providers.dart';
import '../../../vip_gold/domain/vip_tier.dart';
import '../../../vip_gold/presentation/providers/vip_membership_provider.dart';
import '../premium_2026/profile_theme.dart';
import '../widgets/premium/profile_glass.dart';

/// Üyelik rozetleri — `GET /api/membership-badges` yatay şerit.
class ProfileHubMembershipBadgesSection extends ConsumerWidget {
  const ProfileHubMembershipBadgesSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(membershipBadgesCatalogProvider);
    final tier = ref.watch(vipTierProvider);

    return async.when(
      loading: () => const PremiumSkeleton(
        height: 96,
        width: double.infinity,
        borderRadius: BorderRadius.all(Radius.circular(16)),
      ),
      error: (_, _) => const SizedBox.shrink(),
      data: (badges) {
        if (badges.isEmpty) return const SizedBox.shrink();
        return ProfileGlass(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
          borderRadius: ProfilePremiumTheme.radiusMd,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Üyelik Rozetleri',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.92),
                        fontWeight: FontWeight.w900,
                        fontSize: 15,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: () => context.push('/premium-membership'),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: const Text(
                      'Planları Gör',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 11,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              SizedBox(
                height: 80,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: badges.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 10),
                  itemBuilder: (context, i) {
                    final badge = badges[i];
                    final unlocked =
                        badge.isUnlockedFor(tier: tier);
                    return _MembershipBadgeTile(
                      badge: badge,
                      unlocked: unlocked,
                      requiredTier: badge.requiredTier,
                      onTap: () => context.push('/premium-membership'),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _MembershipBadgeTile extends StatelessWidget {
  const _MembershipBadgeTile({
    required this.badge,
    required this.unlocked,
    required this.requiredTier,
    required this.onTap,
  });

  final CosmeticItem badge;
  final bool unlocked;
  final VipTier requiredTier;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final url = badge.previewUrl ?? badge.assetUrl;
    return GestureDetector(
      onTap: onTap,
      child: Opacity(
        opacity: unlocked ? 1 : 0.5,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: unlocked
                          ? ProfilePremiumTheme.neonPurple
                          : Colors.white.withValues(alpha: 0.15),
                      width: unlocked ? 2 : 1,
                    ),
                    boxShadow: unlocked
                        ? [
                            BoxShadow(
                              color: ProfilePremiumTheme.neonPurple
                                  .withValues(alpha: 0.35),
                              blurRadius: 12,
                            ),
                          ]
                        : null,
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: url != null && url.isNotEmpty
                      ? CanlifalNetworkImage(url: url, fit: BoxFit.cover)
                      : Icon(
                          Icons.military_tech_rounded,
                          color: unlocked
                              ? ProfilePremiumTheme.neonPurple
                              : Colors.white54,
                        ),
                ),
                if (!unlocked)
                  Positioned(
                    right: -2,
                    bottom: -2,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: Colors.black87,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.2),
                        ),
                      ),
                      child: const Icon(
                        Icons.lock_rounded,
                        size: 10,
                        color: Colors.white70,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            SizedBox(
              width: 68,
              child: Text(
                badge.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: unlocked ? 0.9 : 0.5),
                  fontSize: 9,
                  fontWeight: unlocked ? FontWeight.w800 : FontWeight.w600,
                ),
              ),
            ),
            Text(
              requiredTier.label,
              style: TextStyle(
                color: Colors.white.withValues(alpha: unlocked ? 0.7 : 0.35),
                fontSize: 8,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
