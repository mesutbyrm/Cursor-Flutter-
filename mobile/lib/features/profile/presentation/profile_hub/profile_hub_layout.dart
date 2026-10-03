import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/motion/canlifal_motion_tokens.dart';
import '../../../../core/motion/canlifal_motion_widgets.dart';
import '../../../membership/presentation/widgets/membership_pending_payment_banner.dart';
import 'admin_profile_header.dart';
import '../premium_2026/profile_screen_state.dart';
import 'profile_hub_error_banner.dart';
import 'mock_profile_header.dart';
import 'profile_hub_tabbed_sections.dart';
import '../../../social/presentation/providers/social_providers.dart';
import '../premium_2026/profile_lazy_sections.dart';

/// Referans profil hub — tek scroll: Header → Avatar/Cover → Stats → rol bölümleri → üyelik/cüzdan → ayarlar.
///
/// Rol çözümü [ProfileScreenState] + `showAdmin` / `showStaff` / `showPublisher` bayraklarından gelir;
/// client tarafında sahte rol üretilmez.
class ProfileHubLayout extends ConsumerWidget {
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
  Widget build(BuildContext context, WidgetRef ref) {
    final postCount =
        ref.watch(userSocialPostsProvider(userId)).valueOrNull?.length;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (showAdmin) ...[
          CanlifalEntranceFadeSlide(
            child: AdminProfileHeader(user: state.user),
          ),
          const SizedBox(height: 8),
          const ProfileHubErrorBanner(),
          const MembershipPendingPaymentBanner(),
        ] else ...[
          CanlifalEntranceFadeSlide(
            child: MockProfileHeader(
              state: state,
              postCount: postCount,
              onRefresh: onRefresh,
            ),
          ),
          const SizedBox(height: 8),
          const ProfileHubErrorBanner(),
          const MembershipPendingPaymentBanner(),
          const SizedBox(height: 10),
          CanlifalEntranceFadeSlide(
            delay: CanlifalMotionTokens.staggerIndex(1, stepMs: 50),
            child: ProfileLazyContent(userId: userId),
          ),
        ],
        const SizedBox(height: 18),
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
