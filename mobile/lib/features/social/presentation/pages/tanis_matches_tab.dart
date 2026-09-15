import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/network/api_exception.dart';
import '../../../../core/widgets/user_avatar.dart';
import '../../../platform_social/presentation/widgets/platform_social_ui_kit.dart';
import '../../domain/entities/social_discovery_user.dart';
import '../providers/social_discovery_providers.dart';
import '../sheets/social_discovery_profile_sheet.dart';
import '../widgets/discovery_swipe_deck.dart';

class TanisMatchesTab extends ConsumerWidget {
  const TanisMatchesTab({super.key, required this.onRefresh});

  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final matches = ref.watch(socialDiscoveryMatchesProvider);

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(socialDiscoveryMatchesProvider);
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
              return _MatchTile(user: u);
            },
          );
        },
      ),
    );
  }
}

class _MatchTile extends StatelessWidget {
  const _MatchTile({required this.user});

  final SocialDiscoveryUser user;

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
              ],
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
