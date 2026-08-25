import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/navigation/unread_badge_format.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/performance/scroll_perf.dart';
import '../../../../core/theme/app_theme_colors.dart';
import '../../../../core/widgets/canlifal_logo.dart';
import '../../../../core/widgets/discover_tab_layout.dart';
import '../../../../core/widgets/user_avatar.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../messages/domain/entities/message_entities.dart';
import '../../../messages/presentation/providers/chat_messages_list_notifier.dart';
import '../../../messages/presentation/providers/conversations_list_notifier.dart';
import '../../../messages/presentation/providers/messages_providers.dart';
import '../../../messages/presentation/widgets/chat_message_actions.dart';
import '../../../notifications/domain/entities/app_notification_entity.dart';
import '../../../notifications/domain/notification_action.dart';
import '../../../notifications/presentation/providers/notifications_list_notifier.dart';
import '../../../notifications/presentation/providers/notifications_providers.dart';
import '../../../admin/presentation/providers/staff_access_provider.dart';
import '../../../live_psychics/presentation/controllers/psychic_incoming_controller.dart';
import '../../../live_psychics/presentation/controllers/psychic_invite_coordinator.dart';
import '../../../live_psychics/presentation/controllers/psychics_list_controller.dart';
import '../../../live_psychics/presentation/providers/psychic_push_payload.dart';
import '../../../voice_hub/presentation/utils/voice_room_session_utils.dart';
import '../../domain/inbox_feed_entry.dart';
import '../providers/inbox_unread_providers.dart';
import '../utils/inbox_notification_visual.dart';
import 'inbox_system_notifications_panel.dart';

/// Tümü sekmesi — DM + sistem bildirimleri kronolojik.
class InboxAllFeedSliver extends ConsumerWidget {
  const InboxAllFeedSliver({
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

  Future<void> _onSystemTap(
    BuildContext context,
    WidgetRef ref,
    AppNotificationEntity n,
  ) async {
    final router = GoRouter.of(context);
    final staffCanManage = ref.read(staffAccessProvider).canManagePayments;

    Future<void> prepareSwitch(String key, {String source = 'notification'}) =>
        prepareVoiceRoomSwitch(ref, nextLiveKey: key, source: source);

    final invite = psychicInviteFromNotification(n);
    if (invite != null) {
      final uid = ref.read(authControllerProvider).valueOrNull?.id;
      final approved = ref.read(approvedPsychicProvider);
      if (shouldPresentPsychicIncomingInvite(
        authUserId: uid,
        invite: invite,
        tellerProfileId: approved.profile?.id,
        isFortuneTeller:
            approved.profile != null && approved.profile!.isUsable,
      )) {
        ref.read(psychicIncomingQueueProvider.notifier).enqueue(invite);
        PsychicInviteCoordinator.requestPresent(sessionId: invite.sessionId);
      } else {
        await navigateFromNotificationAsync(
          router,
          n,
          staffCanManagePayments: staffCanManage,
          prepareVoiceRoomSwitch: prepareSwitch,
        );
      }
    } else {
      await navigateFromNotificationAsync(
        router,
        n,
        staffCanManagePayments: staffCanManage,
        prepareVoiceRoomSwitch: prepareSwitch,
      );
    }

    if (!n.read) {
      unawaited(markNotificationRead(ref, n.id));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final convState = ref.watch(conversationsListNotifierProvider);
    final notifState = ref.watch(notificationsListNotifierProvider);

    if (convState.isLoading && notifState.isLoading) {
      return const SliverFillRemaining(child: DiscoverAccentLoader());
    }

    final conversations = convState.valueOrNull?.all ?? const [];
    final notifications = notifState.valueOrNull?.all ?? const [];
    final q = query.trim().toLowerCase();

    var feed = mergeInboxFeed(
      conversations: conversations,
      notifications: notifications,
    );

    if (unreadOnly) {
      feed = feed.where((e) => e.isUnread).toList();
    }

    if (q.isNotEmpty) {
      feed = feed.where((e) {
        return switch (e) {
          InboxDmEntry(:final conversation) =>
            conversation.title.toLowerCase().contains(q) ||
                (conversation.subtitle ?? '').toLowerCase().contains(q),
          InboxSystemEntry(:final notification) =>
            notification.title.toLowerCase().contains(q) ||
                (notification.body ?? '').toLowerCase().contains(q) ||
                inboxSystemCategoryLabel(notification.type)
                    .toLowerCase()
                    .contains(q),
        };
      }).toList();
    }

    if (feed.isEmpty) {
      return SliverFillRemaining(
        hasScrollBody: false,
        child: DiscoverEmptyState(
          icon: Icons.inbox_rounded,
          message: unreadOnly
              ? 'Okunmamış mesaj veya bildirim yok.'
              : 'Gelen kutun boş.\nMesajlar ve sistem bildirimleri burada görünür.',
          actionLabel: 'Sosyal akış',
          action: () => context.go('/social'),
        ),
      );
    }

    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 32),
      sliver: SliverList.builder(
        itemCount: feed.length,
        itemBuilder: (ctx, i) {
          final entry = feed[i];
          return ScrollPerf.item(
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: switch (entry) {
                InboxDmEntry(:final conversation) => _DmTile(
                    conversation: conversation,
                    formatTime: _formatTime,
                    onTap: () {
                      unawaited(
                        ref
                            .read(
                              chatMessagesListNotifierProvider(conversation.id)
                                  .notifier,
                            )
                            .refresh(silent: true, forceRefresh: false),
                      );
                      context.push('/chat/${conversation.id}');
                    },
                    onLongPress: () => _showPeerActions(context, ref, conversation),
                  ),
                InboxSystemEntry(:final notification) => InboxSystemNotificationTile(
                    notification: notification,
                    fmt: DateFormat('HH:mm'),
                    onTap: () => _onSystemTap(context, ref, notification),
                  ),
              },
            ),
          );
        },
      ),
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
}

class _DmTile extends StatelessWidget {
  const _DmTile({
    required this.conversation,
    required this.formatTime,
    required this.onTap,
    required this.onLongPress,
  });

  final ConversationEntity conversation;
  final String Function(DateTime?) formatTime;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  @override
  Widget build(BuildContext context) {
    final c = conversation;
    final unread = c.unreadCount > 0;

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: onTap,
        onLongPress: onLongPress,
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          decoration: BoxDecoration(
            color: unread
                ? AppThemeColors.accentPurple.withValues(alpha: 0.18)
                : Colors.white.withValues(alpha: 0.045),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: unread
                  ? AppThemeColors.accentPurple.withValues(alpha: 0.42)
                  : Colors.white.withValues(alpha: 0.07),
            ),
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
                        fontWeight: unread ? FontWeight.w900 : FontWeight.w700,
                        fontSize: 16,
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
                            : Colors.white.withValues(alpha: 0.58),
                        fontSize: 13,
                        fontWeight: unread ? FontWeight.w700 : FontWeight.w500,
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
                    formatTime(c.lastMessageAt),
                    style: TextStyle(
                      fontSize: 11,
                      color: unread
                          ? AppThemeColors.accentPink
                          : Colors.white.withValues(alpha: 0.46),
                      fontWeight: unread ? FontWeight.w800 : FontWeight.w500,
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
                        gradient: const LinearGradient(
                          colors: [Color(0xFF7C3AED), Color(0xFFFF2D8D)],
                        ),
                        borderRadius: BorderRadius.circular(12),
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
    );
  }
}

/// Sabitlenmiş Canlifal Sistemi satırı — Tümü sekmesinde üstte.
class InboxSystemPinnedTile extends ConsumerWidget {
  const InboxSystemPinnedTile({
    super.key,
    required this.onTap,
  });

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unread = ref.watch(inboxSystemUnreadCountProvider);
    final latest = ref.watch(notificationsListNotifierProvider).maybeWhen(
          data: (s) => s.all.isNotEmpty ? s.all.first : null,
          orElse: () => null,
        );

    final preview = latest == null
        ? 'Canlı yayın, sesli oda, kazanç ve diğer uyarılar'
        : (latest.body?.trim().isNotEmpty == true
            ? latest.body!
            : latest.title);

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(22),
        child: InkWell(
          borderRadius: BorderRadius.circular(22),
          onTap: onTap,
          child: Ink(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppThemeColors.accentPurple.withValues(alpha: 0.22),
                  const Color(0xFF7B5CFF).withValues(alpha: 0.12),
                ],
              ),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(
                color: AppThemeColors.accentPurple.withValues(alpha: 0.45),
              ),
            ),
            child: Row(
              children: [
                const CanlifalLogo(size: 44, showWordmark: false),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Text(
                            'Canlifal Sistemi',
                            style: TextStyle(
                              fontWeight: FontWeight.w900,
                              fontSize: 16,
                              color: Colors.white,
                            ),
                          ),
                          if (unread > 0) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 7,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [
                                    Color(0xFF7C3AED),
                                    Color(0xFFFF2D8D),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                UnreadBadgeFormat.label(unread),
                                style: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        preview,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.72),
                          fontSize: 13,
                          fontWeight:
                              unread > 0 ? FontWeight.w700 : FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.chevron_right_rounded,
                  color: Colors.white54,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
