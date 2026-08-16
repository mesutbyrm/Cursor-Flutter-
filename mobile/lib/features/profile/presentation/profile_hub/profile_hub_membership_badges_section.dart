import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/images/canlifal_network_image.dart';
import '../../../../core/ui/premium/premium_skeleton.dart';
import '../../../cosmetics/domain/cosmetic_item.dart';
import '../../../cosmetics/domain/cosmetic_slot.dart';
import '../../../cosmetics/presentation/providers/cosmetics_providers.dart';
import '../../../vip_gold/domain/vip_tier.dart';
import '../../../vip_gold/presentation/providers/vip_membership_provider.dart';
import '../premium_2026/profile_membership_helpers.dart';
import '../premium_2026/profile_theme.dart';
import '../providers/profile_hub_providers.dart';
import '../widgets/premium/profile_glass.dart';

/// Üyelik rozetleri — `GET /api/membership-badges` yatay şerit.
class ProfileHubMembershipBadgesSection extends ConsumerWidget {
  const ProfileHubMembershipBadgesSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(membershipBadgesCatalogProvider);
    final tier = ref.watch(vipTierProvider);
    final membershipInfo = ref.watch(profileMembershipInfoProvider);
    final equippedId =
        ref.watch(cosmeticLoadoutProvider).valueOrNull?.idFor(CosmeticSlot.badge);

    return async.when(
      loading: () => const PremiumSkeleton(
        height: 96,
        width: double.infinity,
        borderRadius: BorderRadius.all(Radius.circular(16)),
      ),
      error: (_, _) => const SizedBox.shrink(),
      data: (badges) {
        if (badges.isEmpty) return const SizedBox.shrink();
        final unlocked =
            badges.where((b) => b.isUnlockedFor(tier: tier)).length;
        final sectionSubtitle = buildMembershipBadgesSectionSubtitle(
          info: membershipInfo,
          unlockedCount: unlocked,
          totalCount: badges.length,
        );
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
                    onPressed: () => context.push('/profile/cosmetics'),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: const Text(
                      'Rozetleri Yönet',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 11,
                      ),
                    ),
                  ),
                ],
              ),
              if (sectionSubtitle.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  sectionSubtitle,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.55),
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    height: 1.25,
                  ),
                ),
              ],
              const SizedBox(height: 10),
              SizedBox(
                height: 80,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: badges.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 10),
                  itemBuilder: (context, i) {
                    final badge = badges[i];
                    final unlocked = badge.isUnlockedFor(tier: tier);
                    final selected = equippedId == badge.id;
                    return _MembershipBadgeTile(
                      badge: badge,
                      unlocked: unlocked,
                      selected: selected,
                      requiredTier: badge.requiredTier,
                      onTap: () => _onBadgeTap(
                        context,
                        ref,
                        badge: badge,
                        unlocked: unlocked,
                        selected: selected,
                      ),
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

  Future<void> _onBadgeTap(
    BuildContext context,
    WidgetRef ref, {
    required CosmeticItem badge,
    required bool unlocked,
    required bool selected,
  }) async {
    if (!unlocked) {
      context.push('/premium-membership');
      return;
    }
    if (selected) return;
    await ref
        .read(cosmeticLoadoutProvider.notifier)
        .equip(CosmeticSlot.badge, badge.id);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${badge.name} rozeti seçildi'),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }
}

class _MembershipBadgeTile extends StatelessWidget {
  const _MembershipBadgeTile({
    required this.badge,
    required this.unlocked,
    required this.selected,
    required this.requiredTier,
    required this.onTap,
  });

  final CosmeticItem badge;
  final bool unlocked;
  final bool selected;
  final VipTier requiredTier;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final url = badge.previewUrl ?? badge.assetUrl;
    final borderColor = selected
        ? ProfilePremiumTheme.neonPink
        : unlocked
            ? ProfilePremiumTheme.neonPurple
            : Colors.white.withValues(alpha: 0.15);

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
                      color: borderColor,
                      width: selected ? 3 : unlocked ? 2 : 1,
                    ),
                    boxShadow: unlocked
                        ? [
                            BoxShadow(
                              color: borderColor.withValues(alpha: 0.35),
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
                if (selected)
                  Positioned(
                    right: -2,
                    bottom: -2,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: ProfilePremiumTheme.neonPink,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white70),
                      ),
                      child: const Icon(
                        Icons.check_rounded,
                        size: 10,
                        color: Colors.white,
                      ),
                    ),
                  )
                else if (!unlocked)
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
                  fontWeight: selected || unlocked
                      ? FontWeight.w800
                      : FontWeight.w600,
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
