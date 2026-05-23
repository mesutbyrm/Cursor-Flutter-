import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/social_refresh_indicator.dart';
import '../../../../core/widgets/user_avatar.dart';
import '../providers/messages_providers.dart';

class ConversationsPage extends ConsumerWidget {
  const ConversationsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final list = ref.watch(conversationsProvider);
    final refreshEdge = MediaQuery.paddingOf(context).top + kToolbarHeight + 4;

    Future<void> onPullRefresh() async {
      ref.invalidate(conversationsProvider);
      await ref.read(conversationsProvider.future);
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mesajlar'),
        actions: [
          IconButton(
            onPressed: () => ref.invalidate(conversationsProvider),
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: list.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text(e.toString())),
        data: (items) {
          if (items.isEmpty) {
            return SocialRefreshIndicator(
              edgeOffset: refreshEdge,
              onRefresh: onPullRefresh,
              child: CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(
                      child: Text(
                        'Henüz mesajın yok',
                        style: TextStyle(color: AppTheme.muted),
                      ),
                    ),
                  ),
                ],
              ),
            );
          }
          return SocialRefreshIndicator(
            edgeOffset: refreshEdge,
            onRefresh: onPullRefresh,
            child: ListView.separated(
              cacheExtent: 600,
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: items.length,
              separatorBuilder: (_, _) => const Divider(height: 1),
              itemBuilder: (ctx, i) {
                final c = items[i];
                return ListTile(
                  leading: UserAvatar(url: c.avatarUrl, radius: 24),
                  title: Text(
                    c.title,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: Text(
                    c.subtitle ?? '',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: AppTheme.muted),
                  ),
                  trailing: c.unreadCount > 0
                      ? CircleAvatar(
                          radius: 11,
                          backgroundColor: AppTheme.accent,
                          child: Text(
                            '${c.unreadCount}',
                            style: const TextStyle(
                              fontSize: 11,
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        )
                      : null,
                  onTap: () => context.push('/chat/${c.id}'),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
