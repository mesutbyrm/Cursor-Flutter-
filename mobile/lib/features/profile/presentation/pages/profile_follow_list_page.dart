import 'package:flutter/material.dart';
import 'package:canlifal_social/core/theme/app_theme_extensions.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/network/api_exception.dart';
import '../../../../core/ui/pro_glass/pro_glass.dart';
import '../../../../core/widgets/discover_tab_layout.dart';
import '../../../../core/widgets/lazy_paginated_list_view.dart';
import '../../../../core/network/user_online_presence_provider.dart';
import '../../../../core/theme/app_theme_colors.dart';
import '../../../../core/widgets/user_avatar.dart';
import '../../../auth/domain/entities/user_entity.dart';
import '../../presentation/providers/profile_providers.dart';
import '../../../feed/presentation/widgets/discover/discover_background.dart';

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

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: DiscoverBackground(
        child: DiscoverSubPage(
          title: tab == ProfileFollowTab.followers ? 'Takipçi' : 'Takip',
          body: usersAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(
              child: Text(ApiException.userMessage(e)),
            ),
            data: (users) => _FollowList(users: users),
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
    if (users.isEmpty) {
      return const Center(child: Text('Henüz kayıt yok'));
    }
    final online = ref.watch(userOnlinePresenceProvider);
    return LazyPaginatedListView(
      itemCount: users.length,
      itemBuilder: (context, index) {
        final u = users[index];
        final isOnline = online.contains(u.id);
        return ListTile(
          leading: Stack(
            clipBehavior: Clip.none,
            children: [
              UserAvatar(url: u.avatarUrl, radius: 22),
              Positioned(
                right: 0,
                bottom: 0,
                child: Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: isOnline
                        ? AppThemeColors.onlineGreen
                        : Colors.grey.shade700,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Theme.of(context).scaffoldBackgroundColor,
                      width: 1.5,
                    ),
                  ),
                ),
              ),
            ],
          ),
          title: Text(u.display, style: Theme.of(context).textTheme.titleSmall),
          subtitle: Text('@${u.username}'),
          onTap: () => context.push('/profile/${u.id}'),
        );
      },
    );
  }
}
