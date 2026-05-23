import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/social_refresh_indicator.dart';
import '../../../../core/widgets/user_avatar.dart';
import '../providers/profile_providers.dart';

class UserProfilePage extends ConsumerWidget {
  const UserProfilePage({super.key, required this.userId});

  final String userId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(userProfileProvider(userId));

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => context.pop(),
        ),
        title: const Text('Profil'),
      ),
      body: userAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text(e.toString())),
        data: (user) {
          final refreshEdge =
              MediaQuery.paddingOf(context).top + kToolbarHeight + 4;
          return SocialRefreshIndicator(
            edgeOffset: refreshEdge,
            onRefresh: () async {
              ref.invalidate(userProfileProvider(userId));
              await ref.read(userProfileProvider(userId).future);
            },
            child: ListView(
              cacheExtent: 600,
              padding: const EdgeInsets.all(20),
              children: [
                Row(
                  children: [
                    UserAvatar(url: user.avatarUrl, radius: 40),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            user.display,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          Text(
                            '@${user.username}',
                            style: const TextStyle(color: AppTheme.muted),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _Stat(label: 'Takipçi', value: '${user.followersCount}'),
                    _Stat(label: 'Takip', value: '${user.followingCount}'),
                  ],
                ),
                const SizedBox(height: 20),
                FilledButton(
                  onPressed: () async {
                    final repo = ref.read(profileRepositoryProvider);
                    if (user.isFollowing) {
                      await repo.unfollow(user.id);
                    } else {
                      await repo.follow(user.id);
                    }
                    ref.invalidate(userProfileProvider(userId));
                  },
                  child: Text(user.isFollowing ? 'Takipten çık' : 'Takip et'),
                ),
                if (user.bio != null && user.bio!.isNotEmpty) ...[
                  const SizedBox(height: 24),
                  Text(user.bio!, style: const TextStyle(height: 1.4)),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
        ),
        Text(label, style: const TextStyle(color: AppTheme.muted)),
      ],
    );
  }
}
