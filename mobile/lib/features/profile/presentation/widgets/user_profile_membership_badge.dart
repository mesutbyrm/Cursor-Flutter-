import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/design_system/cds_fx.dart';
import '../../../vip_gold/domain/vip_tier.dart';
import '../../../vip_gold/presentation/widgets/vip_badge.dart';
import '../premium_2026/profile_membership_helpers.dart';
import '../providers/profile_providers.dart';

/// Başka kullanıcının profilinde ücretli üyelik rozeti.
class UserProfileMembershipBadge extends ConsumerWidget {
  const UserProfileMembershipBadge({super.key, required this.userId});

  final String userId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final extAsync = ref.watch(userProfileExtendedProvider(userId));
    return extAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, _) => const SizedBox.shrink(),
      data: (ext) {
        final info = resolveProfileMembership(rawMembership: ext.vipLevel);
        if (!info.hasPaidTier) return const SizedBox.shrink();
        final fx = ref.watch(cdsFxProvider);
        final shimmer = info.tier.isVip && !fx.decorativeDisabled;
        return Padding(
          padding: const EdgeInsets.only(left: 6),
          // Rozete dokununca üyelik sayfası — ziyaretçi de aynı ayrıcalığı alabilsin.
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () => context.push('/premium-membership'),
            child: VipBadge(tier: info.tier, compact: false, animate: shimmer),
          ),
        );
      },
    );
  }
}

/// Test ve widget dışı kullanım için tier çözümlemesi.
VipTier? membershipTierFromVipLevel(String? vipLevel) {
  final info = resolveProfileMembership(rawMembership: vipLevel);
  return info.hasPaidTier ? info.tier : null;
}
