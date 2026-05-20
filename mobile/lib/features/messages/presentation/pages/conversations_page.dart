import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/network/api_exception.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/shell_app_bar_widgets.dart';
import '../../../../core/widgets/user_avatar.dart';
import '../../../shell/presentation/widgets/branch_quick_actions.dart';
import '../providers/messages_providers.dart';

class ConversationsPage extends ConsumerWidget {
  const ConversationsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final list = ref.watch(conversationsProvider);

    return Scaffold(
      appBar: AppBar(
        leadingWidth: 48,
        leading: const ShellProfileLeading(),
        title: const Text('Mesajlar'),
        actions: [
          const ShellNotificationsButton(),
          const ShellCoinBalanceAction(),
          IconButton(
            tooltip: 'Yenile',
            onPressed: () => ref.invalidate(conversationsProvider),
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: list.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text(ApiException.userMessage(e))),
        data: (items) {
          if (items.isEmpty) {
            return RefreshIndicator(
              color: AppTheme.accent,
              onRefresh: () async {
                ref.invalidate(conversationsProvider);
                await ref.read(conversationsProvider.future);
              },
              child: CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(14, 8, 14, 0),
                    sliver: const SliverToBoxAdapter(
                      child: MessagesBranchQuickActions(),
                    ),
                  ),
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Text(
                          'Henüz mesajın yok',
                          style: TextStyle(
                            color: AppTheme.muted.withValues(alpha: 0.95),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          }
          return RefreshIndicator(
            color: AppTheme.accent,
            onRefresh: () async {
              ref.invalidate(conversationsProvider);
              await ref.read(conversationsProvider.future);
            },
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                const SliverPadding(
                  padding: EdgeInsets.fromLTRB(14, 8, 14, 0),
                  sliver: SliverToBoxAdapter(
                    child: MessagesBranchQuickActions(),
                  ),
                ),
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (ctx, i) {
                      final c = items[i];
                      return Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          ListTile(
                            leading:
                                UserAvatar(url: c.avatarUrl, radius: 24),
                            title: Text(
                              c.title,
                              style: const TextStyle(
                                  fontWeight: FontWeight.w600),
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
                          ),
                          const Divider(height: 1),
                        ],
                      );
                    },
                    childCount: items.length,
                  ),
                ),
                const SliverPadding(padding: EdgeInsets.only(bottom: 24)),
              ],
            ),
          );
        },
      ),
    );
  }
}
