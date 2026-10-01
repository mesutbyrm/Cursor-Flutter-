import '../../../../core/design_system/cds_skeleton.dart';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:canlifal_social/core/theme/app_theme_extensions.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_theme_colors.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/performance/scroll_perf.dart';
import '../../../../core/widgets/discover_tab_layout.dart';
import '../../../../core/widgets/user_avatar.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../domain/entities/message_entities.dart';
import '../providers/chat_messages_list_notifier.dart';
import '../../../../core/navigation/unread_badge_format.dart';
import '../providers/conversations_list_notifier.dart';
import '../providers/messages_providers.dart';
import 'chat_message_actions.dart';

/// WhatsApp tarzı konuşma listesi.
class ConversationsListSliver extends ConsumerWidget {
  const ConversationsListSliver({
    super.key,
    this.query = '',
    this.unreadOnly = false,
  });

  final String query;
  final bool unreadOnly;

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
          loading: () => SliverFillRemaining(
            hasScrollBody: false,
            child: CdsSkeleton.listRows(),
          ),
          error: (e, _) => SliverFillRemaining(
            child: DiscoverEmptyState(
              icon: Icons.chat_bubble_outline,
              message: ApiException.userMessage(e),
              actionLabel: 'Yenile',
              action: () => _refresh(ref),
            ),
          ),
          data: (state) {
            final q = query.trim().toLowerCase();
            final filteredAll = state.all.where((c) {
              if (unreadOnly && c.unreadCount <= 0) return false;
              if (q.isEmpty) return true;
              return c.title.toLowerCase().contains(q) ||
                  (c.subtitle ?? '').toLowerCase().contains(q);
            }).toList();
            final items = filteredAll
                .take(state.visibleCount.clamp(0, filteredAll.length))
                .toList();
            if (state.all.isEmpty || items.isEmpty) {
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
              padding: const EdgeInsets.fromLTRB(0, 0, 0, 32),
              sliver: SliverList.builder(
                itemCount: items.length + (state.hasMore && q.isEmpty ? 1 : 0),
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
                          ? const Color(0xFF25D366).withValues(alpha: 0.08)
                          : context.colors.surface,
                      child: InkWell(
                          onTap: () {
                            unawaited(
                              ref
                                  .read(
                                    chatMessagesListNotifierProvider(c.id)
                                        .notifier,
                                  )
                                  .refresh(silent: true, forceRefresh: false),
                            );
                            context.push('/chat/${c.id}');
                          },
                          onLongPress: () => _showPeerActions(context, ref, c),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 10,
                            ),
                            child: Row(
                              children: [
                                Stack(
                                  clipBehavior: Clip.none,
                                  children: [
                                    UserAvatar(url: c.avatarUrl, radius: 26),
                                    Positioned(
                                      right: 0,
                                      bottom: 1,
                                      child: Container(
                                        width: 12,
                                        height: 12,
                                        decoration: BoxDecoration(
                                          color: c.isOnline
                                              ? const Color(0xFF22C55E)
                                              : Colors.grey.shade700,
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                            color: context.scaffoldBg,
                                            width: 2,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        c.title,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 16,
                                          color: context.colors.onSurface,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        c.subtitle ?? '',
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          color: context.colors.onSurfaceMuted,
                                          fontSize: 14,
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
                                        fontSize: 11,
                                        color: unread
                                            ? AppThemeColors.accentPink
                                            : context.colors.onSurfaceMuted,
                                        fontWeight: unread
                                            ? FontWeight.w800
                                            : FontWeight.w500,
                                      ),
                                    ),
                                    if (unread) ...[
                                      const SizedBox(height: 7),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 7,
                                          vertical: 3,
                                        ),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF25D366),
                                          borderRadius:
                                              BorderRadius.circular(12),
                                        ),
                                        child: Text(
                                          UnreadBadgeFormat.label(c.unreadCount),
                                          style: const TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w900,
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
