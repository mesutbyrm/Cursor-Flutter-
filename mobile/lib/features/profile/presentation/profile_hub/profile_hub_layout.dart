import 'package:flutter/material.dart';

import '../premium_2026/profile_lazy_sections.dart';
import '../premium_2026/profile_screen_state.dart';
import 'profile_hub_about_stats_row.dart';
import 'profile_hub_badges_section.dart';
import 'profile_hub_membership_badges_section.dart';
import 'profile_hub_membership_shortcuts.dart';
import 'profile_hub_currency_card.dart';
import 'profile_hub_header.dart';
import 'profile_hub_quick_menu.dart';
import 'profile_hub_services_row.dart';
import 'profile_hub_share_card.dart';
import 'profile_hub_top_gifts_section.dart';
import 'profile_hub_vip_banner.dart';
import '../../../shorts/presentation/widgets/shorts_profile_content.dart';

/// Referans profil hub düzeni.
class ProfileHubLayout extends StatelessWidget {
  const ProfileHubLayout({
    super.key,
    required this.state,
    required this.userId,
    this.onRefresh,
    this.showAdmin = false,
    this.showPublisher = false,
    this.onLogout,
  });

  final ProfileScreenState state;
  final String userId;
  final VoidCallback? onRefresh;
  final bool showAdmin;
  final bool showPublisher;
  final VoidCallback? onLogout;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ProfileHubHeader(state: state, onRefresh: onRefresh),
        const SizedBox(height: 16),
        ShortsProfileStatsRow(
          userId: userId,
          fallbackFollowers: state.followers,
          fallbackFollowing: state.following,
          fallbackLikes: state.stats.likes,
        ),
        const SizedBox(height: 14),
        ProfileHubCurrencyCard(state: state),
        const SizedBox(height: 14),
        ProfileHubVipBanner(
          membership: state.wallet?.membership,
          daysRemaining: state.membershipDays,
          expiresAt: state.wallet?.membershipExpiresAt,
        ),
        const SizedBox(height: 16),
        const ProfileHubQuickMenu(),
        const SizedBox(height: 16),
        ProfileHubAboutStatsRow(
          user: state.user,
          stats: state.stats,
        ),
        const SizedBox(height: 12),
        ProfileHubShareCard(
          username: state.user.username,
          displayName: state.user.display,
        ),
        const SizedBox(height: 12),
        const ProfileHubMembershipBadgesSection(),
        const SizedBox(height: 12),
        const ProfileHubMembershipShortcuts(),
        const SizedBox(height: 12),
        LayoutBuilder(
          builder: (context, c) {
            final wide = c.maxWidth >= 600;
            final badges = const ProfileHubBadgesSection();
            final gifts = const ProfileHubTopGiftsSection();
            if (wide) {
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: badges),
                  const SizedBox(width: 12),
                  Expanded(child: gifts),
                ],
              );
            }
            return Column(
              children: [badges, const SizedBox(height: 12), gifts],
            );
          },
        ),
        const SizedBox(height: 16),
        const ProfileHubServicesRow(),
        const SizedBox(height: 22),
        ProfileLazyContent(userId: userId),
        if (showPublisher) ...[
          const SizedBox(height: 22),
          const ProfileLazyPublisher(),
        ],
        if (showAdmin) ...[
          const SizedBox(height: 22),
          const ProfileLazyAdmin(),
        ],
        if (onLogout != null) ...[
          const SizedBox(height: 22),
          ProfileLazySettings(onLogout: onLogout!),
        ],
      ],
    );
  }
}
