import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../premium_2026/profile_lazy_sections.dart';
import '../premium_2026/profile_screen_state.dart';
import '../providers/profile_hub_providers.dart';
import 'profile_hub_vip_banner.dart';

/// Üyelik alanı — ücretsiz: teşvik banner; ücretli: lazy premium kart.
class ProfileHubMembershipSection extends ConsumerWidget {
  const ProfileHubMembershipSection({super.key, required this.state});

  final ProfileScreenState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final info = ref.watch(profileMembershipInfoProvider);
    if (info.hasActiveSubscription || info.isExpired) {
      return ProfileLazyPremium(base: state);
    }
    return ProfileHubVipBanner(
      membership: state.wallet?.membership,
      daysRemaining: state.membershipDays,
      expiresAt: state.wallet?.membershipExpiresAt,
    );
  }
}
