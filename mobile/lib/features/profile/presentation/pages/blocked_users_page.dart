import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/network/api_exception.dart';
import '../../../../core/widgets/discover_tab_layout.dart';
import '../../../../core/widgets/user_avatar.dart';
import '../../../auth/domain/entities/user_entity.dart';
import '../../../feed/presentation/widgets/discover/discover_background.dart';
import '../providers/profile_providers.dart';

/// Engellenen kullanıcılar — kılavuz §9.2 `GET /api/user/blocked`.
class BlockedUsersPage extends ConsumerWidget {
  const BlockedUsersPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(blockedUsersProvider);
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: DiscoverBackground(
        child: DiscoverSubPage(
          title: 'Engellenenler',
          subtitle: 'Engellediğin hesaplar',
          body: async.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(ApiException.userMessage(e)),
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: () => ref.invalidate(blockedUsersProvider),
                    child: const Text('Tekrar dene'),
                  ),
                ],
              ),
            ),
            data: (users) {
              if (users.isEmpty) {
                return const Center(child: Text('Engellenen kullanıcı yok'));
              }
              return RefreshIndicator(
                onRefresh: () async => ref.invalidate(blockedUsersProvider),
                child: ListView.builder(
                  itemCount: users.length,
                  itemBuilder: (context, i) {
                    final u = users[i];
                    return ListTile(
                      leading: UserAvatar(url: u.avatarUrl, radius: 22),
                      title: Text(u.display),
                      subtitle: Text('@${u.username}'),
                      onTap: () => context.push('/user/${u.id}'),
                    );
                  },
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
