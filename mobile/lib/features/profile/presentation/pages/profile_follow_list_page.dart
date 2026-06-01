import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/network/api_exception.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/ui/pro_glass/pro_glass.dart';
import '../../../../core/widgets/discover_tab_layout.dart';
import '../../../../core/widgets/lazy_paginated_list_view.dart';
import '../../../../core/widgets/user_avatar.dart';
import '../../../auth/domain/entities/user_entity.dart';
import '../../data/datasources/profile_remote_datasource.dart';
import '../../../../core/network/dio_provider.dart';
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
    final future = tab == ProfileFollowTab.followers
        ? ProfileRemoteDataSource(ref.watch(dioProvider)).followers(userId)
        : ProfileRemoteDataSource(ref.watch(dioProvider)).following(userId);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: DiscoverBackground(
        child: DiscoverSubPage(
          title: tab == ProfileFollowTab.followers ? 'Takipçi' : 'Takip',
          body: FutureBuilder<List<UserEntity>>(
            future: future,
            builder: (context, snap) {
              if (snap.connectionState != ConnectionState.done) {
                return const Center(child: DiscoverAccentLoader());
              }
              if (snap.hasError) {
                return DiscoverEmptyState(
                  icon: Icons.error_outline_rounded,
                  message: ApiException.userMessage(snap.error!),
                );
              }
              final users = snap.data ?? const [];
              if (users.isEmpty) {
                return DiscoverEmptyState(
                  icon: Icons.people_outline_rounded,
                  message: tab == ProfileFollowTab.followers
                      ? 'Henüz takipçi yok.'
                      : 'Henüz kimseyi takip etmiyorsun.',
                );
              }
              return LazyPaginatedListView(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
                itemCount: users.length,
                itemBuilder: (context, i) {
                  final u = users[i];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: ProGlassListTile(
                    onTap: () => context.push('/user/${u.id}'),
                    child: Row(
                      children: [
                        UserAvatar(url: u.avatarUrl, radius: 22),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                u.display,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              Text(
                                '@${u.username}',
                                style: TextStyle(
                                  color: AppColors.textMuted
                                      .withValues(alpha: 0.85),
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Icon(
                          Icons.chevron_right_rounded,
                          color: AppColors.textMuted.withValues(alpha: 0.6),
                        ),
                      ],
                    ),
                  ),
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }
}
