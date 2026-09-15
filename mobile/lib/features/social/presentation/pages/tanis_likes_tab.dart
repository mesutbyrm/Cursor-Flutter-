import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/network/api_exception.dart';
import '../../../../core/widgets/user_avatar.dart';
import '../../../platform_social/presentation/widgets/platform_social_ui_kit.dart';
import '../../domain/entities/social_discovery_user.dart';
import '../providers/social_discovery_providers.dart';
import '../sheets/social_discovery_profile_sheet.dart';
import '../utils/social_discovery_time_label.dart';
import '../widgets/discovery_swipe_deck.dart';

/// Sana gelen / gönderilen beğeniler (üretim filtre yedekleri).
class TanisLikesTab extends ConsumerStatefulWidget {
  const TanisLikesTab({super.key, required this.onRefresh});

  final Future<void> Function() onRefresh;

  @override
  ConsumerState<TanisLikesTab> createState() => _TanisLikesTabState();
}

class _TanisLikesTabState extends ConsumerState<TanisLikesTab> {
  var _segment = 0;

  @override
  Widget build(BuildContext context) {
    final incoming = ref.watch(socialDiscoveryIncomingLikesProvider);
    final sent = ref.watch(socialDiscoverySentLikesProvider);

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(socialDiscoveryIncomingLikesProvider);
        ref.invalidate(socialDiscoverySentLikesProvider);
        await widget.onRefresh();
      },
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          SegmentedButton<int>(
            segments: const [
              ButtonSegment(value: 0, label: Text('Sana gelen')),
              ButtonSegment(value: 1, label: Text('Gönderilen')),
            ],
            selected: {_segment},
            onSelectionChanged: (s) => setState(() => _segment = s.first),
          ),
          const SizedBox(height: 12),
          if (_segment == 0)
            incoming.when(
              loading: () => const Center(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: CircularProgressIndicator(),
                ),
              ),
              error: (e, _) => Text(ApiException.userMessage(e)),
              data: (users) => _LikeList(
                users: users,
                emptyTitle: 'Henüz sana gelen beğeni yok',
                emptySubtitle:
                    'Biri seni beğendiğinde burada görünür; karşılık beğenince eşleşme oluşur.',
              ),
            )
          else
            sent.when(
              loading: () => const Center(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: CircularProgressIndicator(),
                ),
              ),
              error: (e, _) => Text(ApiException.userMessage(e)),
              data: (users) => _LikeList(
                users: users,
                emptyTitle: 'Henüz beğeni göndermedin',
                emptySubtitle: 'Keşfet sekmesinden beğeni ve süper beğeni gönder.',
              ),
            ),
        ],
      ),
    );
  }
}

class _LikeList extends StatelessWidget {
  const _LikeList({
    required this.users,
    required this.emptyTitle,
    required this.emptySubtitle,
  });

  final List<SocialDiscoveryUser> users;
  final String emptyTitle;
  final String emptySubtitle;

  @override
  Widget build(BuildContext context) {
    if (users.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: DiscoverEmptyInline(
          icon: Icons.favorite_outline_rounded,
          title: emptyTitle,
          subtitle: emptySubtitle,
        ),
      );
    }
    return Column(
      children: [
        for (final u in users) ...[
          PlatformSocialGlassCard(
            onTap: () => showSocialDiscoveryProfileSheet(context, user: u),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                UserAvatar(url: u.avatarUrl, radius: 26),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        u.displayName,
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                      if (u.username != null)
                        Text(
                          '@${u.username}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: PlatformSocialPalette.textMuted,
                          ),
                        ),
                      if (socialDiscoveryRelativeTimeLabel(u.actionAt) != null)
                        Text(
                          socialDiscoveryRelativeTimeLabel(u.actionAt)!,
                          style: const TextStyle(
                            fontSize: 11,
                            color: PlatformSocialPalette.textMuted,
                          ),
                        ),
                    ],
                  ),
                ),
                FilledButton(
                  onPressed: () => context.push('/chat/${u.id}'),
                  style: FilledButton.styleFrom(
                    backgroundColor: PlatformSocialPalette.accent,
                    visualDensity: VisualDensity.compact,
                  ),
                  child: const Text('Mesaj'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
        ],
      ],
    );
  }
}
