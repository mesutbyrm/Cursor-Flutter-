import 'package:flutter/material.dart';
import 'package:canlifal_social/core/theme/app_theme_extensions.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/bootstrap/startup_perf.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/performance/scroll_perf.dart';
import '../../../../core/ui/pro_glass/pro_glass.dart';
import '../../../../core/widgets/discover_tab_layout.dart';
import '../../../../core/widgets/user_avatar.dart';
import '../providers/conversations_list_notifier.dart';

/// Konuşma listesi — yalnızca liste provider'ını izler.
class ConversationsListSliver extends ConsumerStatefulWidget {
  const ConversationsListSliver({super.key});

  @override
  ConsumerState<ConversationsListSliver> createState() =>
      _ConversationsListSliverState();
}

class _ConversationsListSliverState extends ConsumerState<ConversationsListSliver> {
  var _ready = false;

  @override
  void initState() {
    super.initState();
    Future<void>.delayed(LazyLoadPerf.messagesList, () {
      if (mounted) setState(() => _ready = true);
    });
  }

  Future<void> _refresh() async {
    await ref.read(conversationsListNotifierProvider.notifier).refresh();
  }

  @override
  Widget build(BuildContext context) {
    if (!_ready) {
      return const SliverFillRemaining(child: DiscoverAccentLoader());
    }

    return ref.watch(conversationsListNotifierProvider).when(
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
              sliver: SliverList.builder(
                itemCount: items.length + (state.hasMore ? 1 : 0),
                itemBuilder: (ctx, i) {
                  if (i >= items.length) {
                    return const Padding(
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
                  final c = items[i];
                  return ScrollPerf.item(
                    Padding(
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
                          const SizedBox(width: 14),
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
                                const SizedBox(height: 4),
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
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                ),
                              ),
                            )
                          else
                            Icon(
                              Icons.chevron_right_rounded,
                              color: context.colors.onSurfaceMuted
                                  .withValues(alpha: 0.6),
                            ),
                        ],
                      ),
                    ),
                    ),
                  );
                },
              ),
            );
          },
        );
  }
}
