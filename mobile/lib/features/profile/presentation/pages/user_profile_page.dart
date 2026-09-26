import 'package:canlifal_social/core/theme/app_theme_colors.dart';
import 'package:canlifal_social/core/theme/app_theme_extensions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/auth/staff_roles.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/performance/scroll_perf.dart';
import '../../../../core/ui/premium_2026/premium_2026.dart';
import '../../../../core/widgets/discover_tab_layout.dart';
import '../../../../core/widgets/user_avatar.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../moderation/domain/entities/report_target.dart';
import '../../../moderation/presentation/utils/open_report_flow.dart';
import '../providers/profile_providers.dart';
import '../widgets/premium/profile_glass.dart';
import '../widgets/user_profile_membership_badge.dart';
import '../widgets/user_profile_info_card.dart';
import '../widgets/user_profile_membership_upsell.dart';
import '../widgets/user_profile_role_ribbon.dart';
import '../../../shorts/presentation/widgets/shorts_profile_content.dart';
import '../widgets/user_posts_timeline.dart';
import '../widgets/profile_follow_button.dart';

class UserProfilePage extends ConsumerWidget {
  const UserProfilePage({super.key, required this.userId, this.focusPostId});

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
          message: ApiException.userMessage(e),
          actionLabel: 'Geri',
          action: () => context.pop(),
        ),
        data: (user) {
          // Kurucu / Admin → özel (altın/mor) kapak + avatar çerçevesi.
          final isFounder = StaffRoles.isFounderUser(
            role: user.role,
            username: user.username,
          );
          final isAdmin =
              !isFounder &&
              StaffRoles.isSiteAdminUser(
                role: user.role,
                username: user.username,
              );
          final honorCover = isFounder
              ? const [Color(0xFF3A2A00), Color(0xFFB8860B), Color(0xFFFFD54F)]
              : isAdmin
              ? const [Color(0xFF1E1246), Color(0xFF6D28D9), Color(0xFFA78BFA)]
              : null;
          final honorRing = isFounder
              ? const [Color(0xFFFFD54F), Color(0xFFFF8A00)]
              : isAdmin
              ? const [Color(0xFF8B5CF6), Color(0xFF6366F1)]
              : null;
          return CustomScrollView(
            physics: PremiumMotion.listPhysics,
            scrollCacheExtent: ScrollPerf.scrollCache(
              ScrollPerf.feedCacheExtent,
            ),
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
                                  colors:
                                      honorCover ??
                                      [
                                        const Color(0xFF2A1248),
                                        AppThemeColors.accentPurple.withValues(
                                          alpha: 0.7,
                                        ),
                                        AppThemeColors.accentPink.withValues(
                                          alpha: 0.45,
                                        ),
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
                              gradient: honorRing != null
                                  ? LinearGradient(colors: honorRing)
                                  : context.colors.brandGradient,
                              boxShadow: honorRing != null
                                  ? [
                                      BoxShadow(
                                        color: honorRing.first.withValues(
                                          alpha: 0.55,
                                        ),
                                        blurRadius: 18,
                                        spreadRadius: 1,
                                      ),
                                    ]
                                  : null,
                            ),
                            child: Container(
                              padding: const EdgeInsets.all(3),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: context.scaffoldBg,
                              ),
                              child: UserAvatar(
                                url: user.avatarUrl,
                                radius: 48,
                              ),
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
                    // Kurucu / Admin onur şeridi (ikisi de değilse görünmez).
                    Center(
                      child: UserProfileRoleRibbon(
                        role: user.role,
                        username: user.username,
                      ),
                    ),
                    const SizedBox(height: 18),
                    ShortsProfileStatsRow(
                      userId: userId,
                      fallbackFollowers: user.followersCount,
                      fallbackFollowing: user.followingCount,
                    ),
                    const SizedBox(height: 18),
                    if (!isSelf)
                      _VisitorActions(
                        userId: user.id,
                        isFollowing: user.isFollowing,
                      )
                    else
                      FilledButton.tonalIcon(
                        onPressed: () => context.go('/profile'),
                        style: FilledButton.styleFrom(
                          minimumSize: const Size.fromHeight(46),
                        ),
                        icon: const Icon(Icons.edit_rounded, size: 18),
                        label: const Text('Profilimi düzenle'),
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
                    // Zengin bilgi kartı — şehir, burç, favori takım, katılma,
                    // çevrimiçi, günlük seri, VIP (veri varsa görünür).
                    UserProfileInfoCard(userId: userId),
                    // Ücretli üyeye sahip profil → ziyaretçiye üyelik çağrısı.
                    UserProfileMembershipUpsell(userId: userId, isSelf: isSelf),
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

/// Ziyaretçi eylemleri — takip, mesaj, canlı yayınlar.
class _VisitorActions extends StatelessWidget {
  const _VisitorActions({required this.userId, required this.isFollowing});

  final String userId;
  final bool isFollowing;

  @override
  Widget build(BuildContext context) {
    const compact = ButtonStyle(
      minimumSize: WidgetStatePropertyAll(Size.fromHeight(46)),
      padding: WidgetStatePropertyAll(EdgeInsets.symmetric(horizontal: 10)),
    );
    return Row(
      children: [
        Expanded(
          flex: 5,
          child: ProfileFollowButton(userId: userId, isFollowing: isFollowing),
        ),
        const SizedBox(width: 8),
        Expanded(
          flex: 4,
          child: OutlinedButton.icon(
            style: compact,
            onPressed: () => context.push('/chat/$userId'),
            icon: const Icon(Icons.chat_bubble_outline_rounded, size: 18),
            label: const Text('Mesaj', maxLines: 1),
          ),
        ),
        const SizedBox(width: 8),
        IconButton.outlined(
          tooltip: 'Canlı yayınlar',
          onPressed: () => context.push('/canli-falcilar'),
          constraints: const BoxConstraints.tightFor(width: 46, height: 46),
          style: IconButton.styleFrom(
            side: BorderSide(color: Theme.of(context).colorScheme.outline),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          icon: const Icon(Icons.live_tv_rounded, size: 20),
        ),
      ],
    );
  }
}
