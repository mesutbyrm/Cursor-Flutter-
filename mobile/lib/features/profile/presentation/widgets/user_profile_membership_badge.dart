import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
        return Padding(
          padding: const EdgeInsets.only(left: 6),
          child: VipBadge(tier: info.tier, compact: false),
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
