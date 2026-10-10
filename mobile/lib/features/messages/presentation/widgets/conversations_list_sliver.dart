import '../../../../core/design_system/cds_skeleton.dart';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/network/api_exception.dart';
import '../../../../core/performance/scroll_perf.dart';
import '../../../../core/widgets/discover_tab_layout.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../domain/entities/message_entities.dart';
import '../providers/chat_messages_list_notifier.dart';
import '../providers/conversations_list_notifier.dart';
import '../providers/messages_providers.dart';
import 'chat_message_actions.dart';
import 'conversation_tile.dart';

/// WhatsApp tarzı konuşma listesi.
class ConversationsListSliver extends ConsumerWidget {
  const ConversationsListSliver({
    super.key,
    this.query = '',
    this.unreadOnly = false,
  });

  final String query;
  final bool unreadOnly;

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
                  return ScrollPerf.item(
                    ConversationTile(
                      conversation: c,
                      onTap: () {
                        unawaited(
                          ref
                              .read(chatMessagesListNotifierProvider(c.id).notifier)
                              .refresh(silent: true, forceRefresh: false),
                        );
                        context.push('/chat/${c.id}');
                      },
                      onLongPress: () => _showPeerActions(context, ref, c),
                    ),
                  );
                },
              ),
            );
          },
        );
  }
}
