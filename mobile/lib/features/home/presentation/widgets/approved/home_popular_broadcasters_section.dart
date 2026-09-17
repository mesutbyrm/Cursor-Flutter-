import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:canlifal_social/core/images/canlifal_network_image.dart';

import '../../../../live/domain/entities/live_stream_entity.dart';
import '../../../../live/presentation/utils/open_live_stream.dart';
import '../../providers/home_providers.dart';
import '../../theme/home_approved_design.dart';
import '../premium_2026/home_horizontal_list.dart';
import '../premium_2026/home_section_shell.dart';
import 'live_stream_preview_media.dart';

/// Popüler yayıncılar — canlı liste verisinden (izleyici sıralı, benzersiz host).
class HomePopularBroadcastersSection extends ConsumerWidget {
  const HomePopularBroadcastersSection({super.key});

  static const _cardW = 118.0;
  static const _cardH = 156.0;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final streams = ref.watch(homeLiveStreamsProvider);

    return streams.when(
      loading: () => HomeSectionShell(
        emoji: '⭐',
        title: 'Popüler Yayıncılar',
        actionLabel: 'Tümünü Gör >',
        onAction: () => context.go('/live'),
        contentHeight: _cardH,
        loading: HomeHorizontalList(
          height: _cardH,
          itemCount: 4,
          itemBuilder: (_, __) => Container(
            width: _cardW,
            decoration: BoxDecoration(
              color: HomeApprovedDesign.surface.withValues(alpha: 0.5),
              borderRadius:
                  BorderRadius.circular(HomeApprovedDesign.cardRadius),
            ),
          ),
        ),
      ),
      error: (_, __) => const SizedBox.shrink(),
      data: (items) {
        final ranked = _rankUniqueHosts(items);
        if (ranked.isEmpty) return const SizedBox.shrink();

        return HomeSectionShell(
          emoji: '⭐',
          title: 'Popüler Yayıncılar',
          actionLabel: 'Tümünü Gör >',
          onAction: () => context.go('/live'),
          child: HomeHorizontalList(
            height: _cardH,
            itemCount: ranked.length.clamp(0, 12),
            itemBuilder: (context, i) {
              final stream = ranked[i];
              return _BroadcasterCard(
                stream: stream,
                onTap: () => openLiveStreamNative(context, ref, stream),
              );
            },
          ),
        );
      },
    );
  }

  static List<LiveStreamEntity> _rankUniqueHosts(List<LiveStreamEntity> items) {
    final byHost = <String, LiveStreamEntity>{};
    for (final s in items) {
      final key = s.hostUserId?.trim().isNotEmpty == true
          ? s.hostUserId!.trim()
          : s.streamerName ?? s.id;
      final existing = byHost[key];
      if (existing == null ||
          (s.viewerCount) > (existing.viewerCount)) {
        byHost[key] = s;
      }
    }
    final list = byHost.values.toList();
    list.sort((a, b) => b.viewerCount.compareTo(a.viewerCount));
    return list;
  }
}

class _BroadcasterCard extends StatelessWidget {
  const _BroadcasterCard({
    required this.stream,
    required this.onTap,
  });

  final LiveStreamEntity stream;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final avatar = stream.thumbnailUrl?.trim() ?? '';
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: HomePopularBroadcastersSection._cardW,
        child: Column(
          children: [
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(
                      HomeApprovedDesign.cardRadius,
                    ),
                    child: LiveStreamPreviewMedia(stream: stream),
                  ),
                  if (stream.isLive)
                    Positioned(
                      top: 6,
                      left: 6,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: HomeApprovedDesign.liveRed,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          'CANLI',
                          style: TextStyle(
                            fontSize: 8,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                if (avatar.isNotEmpty)
                  ClipOval(
                    child: CanlifalNetworkImage(
                      url: avatar,
                      width: 28,
                      height: 28,
                      fit: BoxFit.cover,
                    ),
                  )
                else
                  const CircleAvatar(radius: 14, child: Icon(Icons.person, size: 16)),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    stream.streamerName ?? 'Yayıncı',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: HomeApprovedDesign.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
