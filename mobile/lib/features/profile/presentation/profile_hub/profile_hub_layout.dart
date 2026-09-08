import 'package:flutter/material.dart';

import '../../../membership/presentation/widgets/membership_pending_payment_banner.dart';
import '../premium_2026/profile_screen_state.dart';
import 'profile_hub_error_banner.dart';
import 'profile_hub_header.dart';
import 'profile_hub_tabbed_sections.dart';
import '../../../shorts/presentation/widgets/shorts_profile_content.dart';

/// Referans profil hub düzeni — accordion kartlar.
class ProfileHubLayout extends StatelessWidget {
  const ProfileHubLayout({
    super.key,
    required this.state,
    required this.userId,
    this.onRefresh,
    this.showAdmin = false,
    this.showStaff = false,
    this.showPublisher = false,
    this.onLogout,
  });

  final ProfileScreenState state;
  final String userId;
  final VoidCallback? onRefresh;
  final bool showAdmin;
  final bool showStaff;
  final bool showPublisher;
  final VoidCallback? onLogout;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ProfileHubHeader(state: state, onRefresh: onRefresh),
        const SizedBox(height: 12),
        const ProfileHubErrorBanner(),
        const SizedBox(height: 4),
        ShortsProfileStatsRow(
          userId: userId,
          fallbackFollowers: state.followers,
          fallbackFollowing: state.following,
          fallbackLikes: state.stats.likes,
        ),
        const SizedBox(height: 14),
        const MembershipPendingPaymentBanner(),
        ProfileHubTabbedSections(
          state: state,
          userId: userId,
          onRefresh: onRefresh,
          showAdmin: showAdmin,
          showStaff: showStaff,
          showPublisher: showPublisher,
          onLogout: onLogout,
        ),
      ],
    );
  }
}
