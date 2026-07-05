import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/network/api_exception.dart';
import '../../../../core/performance/scroll_perf.dart';
import '../../../../core/widgets/discover_tab_layout.dart';
import '../../../../core/widgets/user_avatar.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../domain/entities/message_entities.dart';
import '../providers/conversations_list_notifier.dart';
import '../providers/messages_providers.dart';
import 'chat_message_actions.dart';

/// WhatsApp tarzı konuşma listesi.
class ConversationsListSliver extends ConsumerWidget {
  const ConversationsListSliver({super.key});

  String _formatTime(DateTime? dt) {
    if (dt == null) return '';
    final local = dt.toLocal();
    final now = DateTime.now();
    if (local.year == now.year &&
        local.month == now.month &&
        local.day == now.day) {
      return DateFormat.Hm('tr').format(local);
    }
    if (now.difference(local).inDays < 7) {
      return DateFormat.E('tr').format(local);
    }
    return DateFormat('d MMM', 'tr').format(local);
  }

  Future<void> _refresh(WidgetRef ref) async {
    await ref.read(conversationsListNotifierProvider.notifier).refresh(
          forceRefresh: true,
        );
  }

  Future<void> _showPeerActions(
    BuildContext context,
    WidgetRef ref,
    ConversationEntity c,
  ) async {
    await showConversationPeerActions(
      context: context,
      peerName: c.title,
      onDeleteChat: () async {
        final uid = ref.read(authControllerProvider).valueOrNull?.id;
        await ref.read(messagesRepositoryProvider).hideConversation(
              c.id,
              currentUserId: uid,
            );
        await ref
            .read(conversationsListNotifierProvider.notifier)
            .refresh(forceRefresh: true);
      },
      onBlock: () async {
        try {
          await ref.read(messagesRepositoryProvider).blockUser(c.id);
          final uid = ref.read(authControllerProvider).valueOrNull?.id;
          await ref.read(messagesRepositoryProvider).hideConversation(
                c.id,
                currentUserId: uid,
              );
          await ref
              .read(conversationsListNotifierProvider.notifier)
              .refresh(forceRefresh: true);
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('${c.title} engellendi')),
            );
          }
        } catch (e) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(ApiException.userMessage(e))),
            );
          }
        }
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ref.watch(conversationsListNotifierProvider).when(
          loading: () => const SliverFillRemaining(child: DiscoverAccentLoader()),
          error: (e, _) => SliverFillRemaining(
            child: DiscoverEmptyState(
              icon: Icons.chat_bubble_outline,
              message: ApiException.userMessage(e),
              actionLabel: 'Yenile',
              action: () => _refresh(ref),
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
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 32),
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
                  final unread = c.unreadCount > 0;
                  return ScrollPerf.item(
                    Material(
                      color: unread
                          ? const Color(0xFF005C4B).withValues(alpha: 0.12)
                          : Colors.transparent,
                      child: InkWell(
                        onTap: () => context.push('/chat/${c.id}'),
                        onLongPress: () => _showPeerActions(context, ref, c),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 12,
                          ),
                          child: Row(
                            children: [
                              UserAvatar(url: c.avatarUrl, radius: 28),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      c.title,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontWeight: unread
                                            ? FontWeight.w800
                                            : FontWeight.w600,
                                        fontSize: 18,
                                        color: Colors.white,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      c.subtitle ?? '',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        color: unread
                                            ? Colors.white.withValues(alpha: 0.92)
                                            : Colors.white.withValues(alpha: 0.62),
                                        fontSize: 16,
                                        fontWeight: unread
                                            ? FontWeight.w600
                                            : FontWeight.w400,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    _formatTime(c.lastMessageAt),
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: unread
                                          ? const Color(0xFF25D366)
                                          : Colors.white.withValues(alpha: 0.5),
                                      fontWeight: unread
                                          ? FontWeight.w700
                                          : FontWeight.w400,
                                    ),
                                  ),
                                  if (unread) ...[
                                    const SizedBox(height: 6),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 7,
                                        vertical: 3,
                                      ),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF25D366),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        c.unreadCount > 99
                                            ? '99+'
                                            : '${c.unreadCount}',
                                        style: const TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w800,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ],
                          ),
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
