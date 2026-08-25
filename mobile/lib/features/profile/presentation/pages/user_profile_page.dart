import 'package:canlifal_social/core/theme/app_theme_colors.dart';
import 'package:canlifal_social/core/theme/app_theme_extensions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/performance/scroll_perf.dart';
import '../../../../core/ui/premium_2026/premium_2026.dart';
import '../../../../core/widgets/discover_tab_layout.dart';
import '../../../../core/widgets/user_avatar.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../moderation/domain/entities/report_target.dart';
import '../../../moderation/presentation/utils/open_report_flow.dart';
import '../../../gifts/presentation/widgets/direct_gift_send_sheet.dart';
import '../providers/profile_providers.dart';
import '../widgets/premium/profile_glass.dart';
import '../widgets/user_profile_membership_badge.dart';
import '../../../shorts/presentation/providers/shorts_providers.dart';
import '../../../shorts/presentation/widgets/shorts_profile_content.dart';
import '../widgets/user_posts_timeline.dart';

class UserProfilePage extends ConsumerWidget {
  const UserProfilePage({
    super.key,
    required this.userId,
    this.focusPostId,
  });

  final String userId;
  final String? focusPostId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(userProfileProvider(userId));
    final me = ref.watch(authControllerProvider).valueOrNull;
    final isSelf = me != null && me.id == userId;

    return DiscoverSubPage(
      title: 'Profil',
      subtitle: 'Kısa videolar ve paylaşımlar',
      actions: [
        DiscoverIconButton(
          icon: Icons.flag_outlined,
          tooltip: 'Bildir',
          onPressed: () => openReportFlow(
            context,
            ReportTarget(
              type: ReportTargetType.user,
              targetId: userId,
              displayTitle: 'Kullanıcı profili',
            ),
          ),
        ),
      ],
      body: userAsync.when(
        loading: () => const DiscoverAccentLoader(),
        error: (e, _) => DiscoverEmptyState(
          icon: Icons.person_off_outlined,
          message: e.toString(),
        ),
        data: (user) {
          return CustomScrollView(
            physics: PremiumMotion.listPhysics,
            scrollCacheExtent:
                ScrollPerf.scrollCache(ScrollPerf.feedCacheExtent),
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    Stack(
                      clipBehavior: Clip.none,
                      alignment: Alignment.bottomCenter,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: SizedBox(
                            height: 120,
                            width: double.infinity,
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    const Color(0xFF2A1248),
                                    AppThemeColors.accentPurple
                                        .withValues(alpha: 0.7),
                                    AppThemeColors.accentPink
                                        .withValues(alpha: 0.45),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                        Positioned(
                          bottom: -44,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: context.colors.brandGradient,
                            ),
                            child: Container(
                              padding: const EdgeInsets.all(3),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: context.scaffoldBg,
                              ),
                              child: UserAvatar(url: user.avatarUrl, radius: 48),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 52),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Flexible(
                          child: Text(
                            user.display,
                            textAlign: TextAlign.center,
                            style: ProfileTypography.displayName(context),
                          ),
                        ),
                        if (user.isVerified) ...[
                          const SizedBox(width: 6),
                          const ShortsVerifiedBadge(size: 20),
                        ],
                        UserProfileMembershipBadge(userId: userId),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '@${user.username}',
                      textAlign: TextAlign.center,
                      style: ProfileTypography.username(context),
                    ),
                    const SizedBox(height: 18),
                    ShortsProfileStatsRow(
                      userId: userId,
                      fallbackFollowers: user.followersCount,
                      fallbackFollowing: user.followingCount,
                    ),
                    const SizedBox(height: 18),
                    if (!isSelf) ...[
                      Row(
                        children: [
                          Expanded(
                            child: FilledButton(
                              onPressed: () async {
                                final repo = ref.read(profileRepositoryProvider);
                                if (user.isFollowing) {
                                  await repo.unfollow(user.id);
                                } else {
                                  await repo.follow(user.id);
                                }
                                ref.invalidate(userProfileProvider(userId));
                                ref.invalidate(
                                    shortVideoProfileStatsProvider(userId));
                              },
                              style: FilledButton.styleFrom(
                                minimumSize: const Size.fromHeight(52),
                                backgroundColor: user.isFollowing
                                    ? context.colors.surfaceContainer
                                    : AppThemeColors.accentPink,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                              child: Text(
                                user.isFollowing ? 'Takibi bırak' : 'Takip et',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 15,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => context.push('/canli-falcilar'),
                              style: OutlinedButton.styleFrom(
                                minimumSize: const Size.fromHeight(52),
                                foregroundColor: AppThemeColors.accentPink,
                                side: BorderSide(
                                  color: AppThemeColors.accentPink
                                      .withValues(alpha: 0.65),
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                              child: const Text(
                                'Canlı Yayın',
                                style: TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 15,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => showDirectGiftSendSheet(
                                context,
                                ref,
                                receiverUserId: userId,
                                receiverName: user.display,
                              ),
                              style: OutlinedButton.styleFrom(
                                minimumSize: const Size.fromHeight(52),
                                foregroundColor: const Color(0xFFFFD54F),
                                side: BorderSide(
                                  color: const Color(0xFFFFD54F)
                                      .withValues(alpha: 0.65),
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                              child: const Text(
                                'Hediye',
                                style: TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 15,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => context.push('/chat/$userId'),
                              style: OutlinedButton.styleFrom(
                                minimumSize: const Size.fromHeight(52),
                                foregroundColor: AppThemeColors.accentCyan,
                                side: BorderSide(
                                  color: AppThemeColors.accentCyan
                                      .withValues(alpha: 0.65),
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                              child: const Text(
                                'Mesaj',
                                style: TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 15,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ] else
                      FilledButton(
                        onPressed: () => context.go('/profile'),
                        style: FilledButton.styleFrom(
                          minimumSize: const Size.fromHeight(52),
                          backgroundColor: context.colors.surfaceContainer,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: const Text(
                          'Profilimi düzenle',
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 15,
                          ),
                        ),
                      ),
                    if (user.bio != null && user.bio!.isNotEmpty) ...[
                      const SizedBox(height: 14),
                      ProfileGlass(
                        padding: const EdgeInsets.all(16),
                        child: Text(
                          user.bio!,
                          style: ProfileTypography.body(context),
                        ),
                      ),
                    ],
                    const SizedBox(height: 22),
                    ShortsProfileTabs(
                      userId: userId,
                      showLikedTab: isSelf,
                      showSavedTab: isSelf,
                    ),
                    const SizedBox(height: 22),
                    const ProfileSectionTitle(title: 'Paylaşımlar'),
                  ]),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
                sliver: UserPostsTimelineSliver(
                  userId: userId,
                  focusPostId: focusPostId,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
