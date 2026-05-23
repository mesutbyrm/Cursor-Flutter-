import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/network/api_exception.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/discover_tab_layout.dart';
import '../../../../core/widgets/user_avatar.dart';
import '../../../shell/presentation/widgets/branch_quick_actions.dart';
import '../providers/messages_providers.dart';

class ConversationsPage extends ConsumerStatefulWidget {
  const ConversationsPage({super.key});

  @override
  ConsumerState<ConversationsPage> createState() => _ConversationsPageState();
}

class _ConversationsPageState extends ConsumerState<ConversationsPage> {
  Timer? _poll;

  @override
  void initState() {
    super.initState();
    _poll = Timer.periodic(const Duration(seconds: 20), (_) {
      if (!mounted) return;
      ref.invalidate(conversationsProvider);
    });
  }

  @override
  void dispose() {
    _poll?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final list = ref.watch(conversationsProvider);

    return DiscoverTabScrollPage(
      title: 'Mesajlar',
      subtitle: 'Sohbetlerin ve grup mesajların',
      onRefresh: () async => ref.invalidate(conversationsProvider),
      actions: [
        DiscoverIconButton(
          icon: Icons.refresh_rounded,
          onPressed: () => ref.invalidate(conversationsProvider),
        ),
      ],
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
              action: () => ref.invalidate(conversationsProvider),
            ),
          ),
          data: (items) {
            if (items.isEmpty) {
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
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (ctx, i) {
                    final c = items[i];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: DiscoverGlassCard(
                        onTap: () => context.push('/chat/${c.id}'),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 12,
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(2),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: AppColors.brandGradient,
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
                                    style: const TextStyle(
                                      color: AppColors.textMuted,
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
                                  gradient: AppColors.brandGradient,
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
                                color:
                                    AppColors.textMuted.withValues(alpha: 0.6),
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                  childCount: items.length,
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}
