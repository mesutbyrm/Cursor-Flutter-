import 'package:flutter/material.dart';
import 'package:canlifal_social/core/theme/app_theme_extensions.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/network/api_exception.dart';
import '../../../../core/ui/pro_glass/pro_glass.dart';
import '../../../../core/widgets/discover_tab_layout.dart';
import '../../../../core/widgets/lazy_paginated_list_view.dart';
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

class _FollowList extends StatelessWidget {
  const _FollowList({required this.users});

  final List<UserEntity> users;

  @override
  Widget build(BuildContext context) {
    if (users.isEmpty) {
      return const Center(child: Text('Henüz kayıt yok'));
    }
    return LazyPaginatedListView(
      itemCount: users.length,
      itemBuilder: (context, index) {
        final u = users[index];
        return ListTile(
          leading: UserAvatar(url: u.avatarUrl, radius: 22),
          title: Text(u.display, style: context.textTheme.titleSmall),
          subtitle: Text('@${u.username}'),
          onTap: () => context.push('/profile/${u.id}'),
        );
      },
    );
  }
}
