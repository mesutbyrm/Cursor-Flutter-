import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/network/api_exception.dart';
import '../../../../core/widgets/user_avatar.dart';
import '../../../messages/domain/entities/message_entities.dart';
import '../../../messages/presentation/providers/messages_providers.dart';
import '../../../platform_social/presentation/widgets/platform_social_ui_kit.dart';
import '../../domain/entities/social_discovery_user.dart';
import '../providers/social_discovery_providers.dart';
import '../sheets/social_discovery_profile_sheet.dart';
import '../utils/social_discovery_time_label.dart';
import '../widgets/discovery_swipe_deck.dart';

class TanisMatchesTab extends ConsumerWidget {
  const TanisMatchesTab({super.key, required this.onRefresh});

  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final matches = ref.watch(socialDiscoveryMatchesProvider);
    final conversations = ref.watch(conversationsProvider);

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(socialDiscoveryMatchesProvider);
        ref.invalidate(conversationsProvider);
        await onRefresh();
      },
      child: matches.when(
        loading: () => ListView(
          children: const [
            SizedBox(
              height: 200,
              child: Center(child: CircularProgressIndicator()),
            ),
          ],
        ),
        error: (e, _) => ListView(
          children: [
            Padding(
              padding: const EdgeInsets.all(24),
              child: Text(ApiException.userMessage(e)),
            ),
          ],
        ),
        data: (users) {
          final dmByPeer = <String, ConversationEntity>{};
          conversations.valueOrNull?.forEach((c) {
            if (c.id.isNotEmpty) dmByPeer[c.id] = c;
          });
          if (users.isEmpty) {
            return ListView(
              children: [
                const Padding(
                  padding: EdgeInsets.all(32),
                  child: DiscoverEmptyInline(
                    icon: Icons.favorite_border_rounded,
                    title: 'Henüz eşleşme yok',
                    subtitle:
                        'Beğendiğiniz kişi sizi de beğenirse burada görünür.',
                  ),
                ),
              ],
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: users.length,
            separatorBuilder: (_, _) => const SizedBox(height: 10),
            itemBuilder: (context, i) {
              final u = users[i];
              return _MatchTile(user: u, conversation: dmByPeer[u.id]);
            },
          );
        },
      ),
    );
  }
}

class _MatchTile extends StatelessWidget {
  const _MatchTile({required this.user, this.conversation});

  final SocialDiscoveryUser user;
  final ConversationEntity? conversation;

  @override
  Widget build(BuildContext context) {
    return PlatformSocialGlassCard(
      onTap: () => showSocialDiscoveryProfileSheet(context, user: user),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          UserAvatar(url: user.avatarUrl, radius: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.displayName,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                if (user.username != null)
                  Text(
                    '@${user.username}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: PlatformSocialPalette.textMuted,
                    ),
                  ),
                Builder(
                  builder: (context) {
                    final preview = conversation?.subtitle?.trim();
                    final when = socialDiscoveryRelativeTimeLabel(
                      conversation?.lastMessageAt ?? user.actionAt,
                    );
                    final line = preview != null && preview.isNotEmpty
                        ? preview
                        : when;
                    if (line == null || line.isEmpty) {
                      return const SizedBox.shrink();
                    }
                    return Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        preview != null && preview.isNotEmpty && when != null
                            ? '$preview · $when'
                            : line,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12,
                          color: PlatformSocialPalette.textMuted,
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          if (conversation != null && conversation!.unreadCount > 0)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: CircleAvatar(
                radius: 11,
                backgroundColor: PlatformSocialPalette.accent,
                child: Text(
                  conversation!.unreadCount > 9
                      ? '9+'
                      : '${conversation!.unreadCount}',
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          FilledButton.icon(
            onPressed: () => context.push('/chat/${user.id}'),
            icon: const Icon(Icons.chat_bubble_outline_rounded, size: 18),
            label: const Text('Mesaj'),
            style: FilledButton.styleFrom(
              backgroundColor: PlatformSocialPalette.accent,
              visualDensity: VisualDensity.compact,
            ),
          ),
        ],
      ),
    );
  }
}
