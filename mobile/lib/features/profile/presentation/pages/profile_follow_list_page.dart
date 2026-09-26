import 'package:flutter/material.dart';
import 'package:canlifal_social/core/theme/app_theme_extensions.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/design_system/cds_skeleton.dart';
import '../../../../core/motion/canlifal_motion_widgets.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/widgets/discover_tab_layout.dart';
import '../../../../core/widgets/lazy_paginated_list_view.dart';
import '../../../../core/network/user_online_presence_provider.dart';
import '../../../../core/theme/app_theme_colors.dart';
import '../../../../core/widgets/user_avatar.dart';
import '../../../auth/domain/entities/user_entity.dart';
import '../../../social/presentation/utils/social_user_profile_route.dart';
import '../../presentation/providers/profile_providers.dart';
import '../../../feed/presentation/widgets/discover/discover_background.dart';
import '../../../shorts/presentation/widgets/shorts_profile_content.dart'
    show ShortsVerifiedBadge;

enum ProfileFollowTab { followers, following }

class ProfileFollowListPage extends ConsumerWidget {
  const ProfileFollowListPage({
    super.key,
    required this.userId,
    required this.tab,
  });

  final String userId;
  final ProfileFollowTab tab;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final provider = tab == ProfileFollowTab.followers
        ? userFollowersProvider(userId)
        : userFollowingProvider(userId);
    final usersAsync = ref.watch(provider);
    final followers = tab == ProfileFollowTab.followers;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: DiscoverBackground(
        child: DiscoverSubPage(
          title: followers ? 'Takipçi' : 'Takip',
          body: usersAsync.when(
            loading: () => const _FollowListSkeleton(),
            error: (e, _) => DiscoverEmptyState(
              icon: Icons.cloud_off_rounded,
              message: ApiException.userMessage(e),
              actionLabel: 'Tekrar dene',
              action: () => ref.invalidate(provider),
            ),
            data: (users) => users.isEmpty
                ? DiscoverEmptyState(
                    icon: Icons.people_outline_rounded,
                    message: followers
                        ? 'Henüz takipçi yok'
                        : 'Henüz kimse takip edilmiyor',
                  )
                : RefreshIndicator(
                    onRefresh: () async {
                      ref.invalidate(provider);
                      await ref.read(provider.future);
                    },
                    child: _FollowList(users: users),
                  ),
          ),
        ),
      ),
    );
  }
}

class _FollowList extends ConsumerWidget {
  const _FollowList({required this.users});

  final List<UserEntity> users;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final online = ref.watch(userOnlinePresenceProvider);
    return LazyPaginatedListView(
      itemCount: users.length,
      itemBuilder: (context, index) {
        final u = users[index];
        return UserListTile(
          user: u,
          isOnline: online.contains(u.id),
          onTap: () => context.push(buildSocialUserProfileRoute(u.id)),
        );
      },
    );
  }
}

/// Kullanıcı satırı — avatar (çevrimiçi noktası), ad, doğrulama, kullanıcı adı.
class UserListTile extends StatelessWidget {
  const UserListTile({
    super.key,
    required this.user,
    required this.onTap,
    this.isOnline = false,
    this.trailing,
  });

  final UserEntity user;
  final bool isOnline;
  final VoidCallback onTap;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Semantics(
      button: true,
      label:
          '${user.display}, @${user.username}${isOnline ? ', çevrimiçi' : ''}',
      excludeSemantics: true,
      onTap: onTap,
      child: CanlifalPressable(
        scale: 0.98,
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  UserAvatar(url: user.avatarUrl, radius: 24),
                  if (isOnline)
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: Container(
                        width: 13,
                        height: 13,
                        decoration: BoxDecoration(
                          color: AppThemeColors.onlineGreen,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Theme.of(context).scaffoldBackgroundColor,
                            width: 2,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            user.display,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: colors.onSurface,
                            ),
                          ),
                        ),
                        if (user.isVerified) ...[
                          const SizedBox(width: 4),
                          const ShortsVerifiedBadge(size: 14),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '@${user.username}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13,
                        color: colors.onSurfaceMuted,
                      ),
                    ),
                  ],
                ),
              ),
              trailing ??
                  Icon(
                    Icons.chevron_right_rounded,
                    color: colors.onSurfaceMuted,
                  ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FollowListSkeleton extends StatelessWidget {
  const _FollowListSkeleton();

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: ListView.builder(
        physics: const NeverScrollableScrollPhysics(),
        itemCount: 8,
        itemBuilder: (_, _) => Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            children: [
              CdsSkeleton.circle(size: 48),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CdsSkeleton.box(width: 140, height: 12),
                  const SizedBox(height: 8),
                  CdsSkeleton.box(width: 90, height: 10),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
