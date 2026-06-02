import 'dart:async';

import 'package:flutter/material.dart';
import 'package:canlifal_social/core/theme/app_theme_extensions.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/network/api_exception.dart';
import '../../../../core/performance/list_perf.dart';
import '../../../../core/ui/pro_glass/pro_glass.dart';
import '../../../../core/widgets/discover_tab_layout.dart';
import '../../../../core/widgets/messages_notifications_actions.dart';
import '../../../../core/widgets/user_avatar.dart';
import '../../../shell/presentation/widgets/branch_quick_actions.dart';
import '../providers/conversations_list_notifier.dart';
import '../providers/messages_providers.dart';

class ConversationsPage extends ConsumerStatefulWidget {
  const ConversationsPage({super.key});

  @override
  ConsumerState<ConversationsPage> createState() => _ConversationsPageState();
}

class _ConversationsPageState extends ConsumerState<ConversationsPage> {
  Timer? _poll;
  final _scroll = ScrollController();

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_onScroll);
    _poll = Timer.periodic(const Duration(seconds: 20), (_) {
      if (!mounted) return;
      ref.read(conversationsListNotifierProvider.notifier).refresh();
      ref.invalidate(conversationsProvider);
    });
  }

  @override
  void dispose() {
    _poll?.cancel();
    _scroll.removeListener(_onScroll);
    _scroll.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scroll.hasClients) return;
    final pos = _scroll.position;
    if (pos.pixels >= pos.maxScrollExtent - ListPerf.preloadThresholdPx) {
      ref.read(conversationsListNotifierProvider.notifier).loadMore();
    }
  }

  Future<void> _refresh() async {
    await ref.read(conversationsListNotifierProvider.notifier).refresh();
    ref.invalidate(conversationsProvider);
  }

  @override
  Widget build(BuildContext context) {
    final list = ref.watch(conversationsListNotifierProvider);

    return DiscoverTabScrollPage(
      title: 'Mesajlar',
      subtitle: 'Sohbetlerin ve grup mesajların',
      onRefresh: _refresh,
      actions: [
        const MessagesNotificationsActions(spacing: 4),
        DiscoverIconButton(
          icon: Icons.refresh_rounded,
          onPressed: _refresh,
        ),
      ],
      scrollController: _scroll,
      slivers: [
        const SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.fromLTRB(20, 0, 20, 12),
            child: MessagesBranchQuickActions(),
          ),
        ),
        list.when(
          loading: () => const SliverFillRemaining(
            child: DiscoverAccentLoader(),
          ),
          error: (e, _) => SliverFillRemaining(
            child: DiscoverEmptyState(
              icon: Icons.chat_bubble_outline,
              message: ApiException.userMessage(e),
              actionLabel: 'Yenile',
              action: _refresh,
            ),
          ),
          data: (state) {
            final items = state.visible;
            if (state.all.isEmpty) {
              return SliverFillRemaining(
                hasScrollBody: false,
                child: DiscoverEmptyState(
                  icon: Icons.mail_outline_rounded,
                  message:
                      'Henüz mesajın yok.\nProfilden bir kullanıcıya yazarak sohbet başlatabilirsin.',
                  actionLabel: 'Sosyal akış',
                  action: () => context.go('/social'),
                ),
              );
            }
            return SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (ctx, i) {
                    if (i >= items.length) {
                      if (state.hasMore) {
                        return Padding(
                          padding: EdgeInsets.symmetric(vertical: 16),
                          child: Center(
                            child: SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          ),
                        );
                      }
                      return null;
                    }
                    final c = items[i];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: ProGlassListTile(
                        onTap: () => context.push('/chat/${c.id}'),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(2),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: context.colors.brandGradient,
                              ),
                              child: UserAvatar(url: c.avatarUrl, radius: 26),
                            ),
                            SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    c.title,
                                    style: TextStyle(
                                      fontWeight: c.unreadCount > 0
                                          ? FontWeight.w800
                                          : FontWeight.w600,
                                      fontSize: 16,
                                    ),
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    c.subtitle ?? '',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color: context.colors.onSurfaceMuted,
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (c.unreadCount > 0)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  gradient: context.colors.brandGradient,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  '${c.unreadCount}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.white,
                                  ),
                                ),
                              )
                            else
                              Icon(
                                Icons.chevron_right_rounded,
                                color: context.colors.onSurfaceMuted.withValues(alpha: 0.6),
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                  childCount: items.length + (state.hasMore ? 1 : 0),
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}
