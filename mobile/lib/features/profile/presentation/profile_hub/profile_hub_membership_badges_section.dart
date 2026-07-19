import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/images/canlifal_network_image.dart';
import '../../../../core/ui/premium/premium_skeleton.dart';
import '../../../cosmetics/domain/cosmetic_item.dart';
import '../../../cosmetics/presentation/providers/cosmetics_providers.dart';
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
              Text(
                'Üyelik Rozetleri',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.92),
                  fontWeight: FontWeight.w900,
                  fontSize: 15,
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                height: 72,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: badges.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 10),
                  itemBuilder: (context, i) {
                    final badge = badges[i];
                    final active = badge.requiredTier == tier;
                    return _MembershipBadgeTile(badge: badge, active: active);
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
    required this.active,
  });

  final CosmeticItem badge;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final url = badge.previewUrl ?? badge.assetUrl;
    return Opacity(
      opacity: active ? 1 : 0.45,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: active
                    ? ProfilePremiumTheme.neonPurple
                    : Colors.white.withValues(alpha: 0.15),
                width: active ? 2 : 1,
              ),
              boxShadow: active
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
                    color: active
                        ? ProfilePremiumTheme.neonPurple
                        : Colors.white54,
                  ),
          ),
          const SizedBox(height: 4),
          SizedBox(
            width: 64,
            child: Text(
              badge.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white.withValues(alpha: active ? 0.9 : 0.5),
                fontSize: 9,
                fontWeight: active ? FontWeight.w800 : FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
