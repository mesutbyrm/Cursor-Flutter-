import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:canlifal_social/core/theme/app_theme_colors.dart';
import 'package:canlifal_social/core/theme/app_theme_extensions.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/widgets/user_avatar.dart';
import '../../../../feed/presentation/widgets/discover/discover_section_header.dart';
import '../../../../live/domain/entities/live_stream_entity.dart';
import '../../../../live/presentation/providers/live_providers.dart';
import '../../../../live/presentation/utils/open_live_stream.dart';

/// «Aktif Odalar» — canlı yayın yatay şeridi.
class SocialActiveRooms extends ConsumerWidget {
  const SocialActiveRooms({super.key, this.embeddedInFeed = false});

  /// Akışta her 2 gönderi arasında gösterilir.
  final bool embeddedInFeed;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final live = ref.watch(liveStreamsProvider);

    final chips = _buildChips(live.valueOrNull);
    if (chips.isEmpty && live.isLoading) {
      return SizedBox(
        height: 140,
        child: Center(
          child: SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
    }

    final display = chips.isEmpty ? _demoChips() : chips;

    return Padding(
      padding: EdgeInsets.only(
        top: embeddedInFeed ? 4 : 8,
        bottom: embeddedInFeed ? 8 : 12,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (!embeddedInFeed)
            DiscoverSectionHeader(
              title: 'Aktif Yayınlar',
              actionLabel: 'Tümünü Gör',
              onAction: () => context.go('/live'),
            )
          else
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
              child: Row(
                children: [
                  Icon(
                    Icons.live_tv_rounded,
                    size: 18,
                    color: AppThemeColors.accentPurple.withValues(alpha: 0.95),
                  ),
                  SizedBox(width: 8),
                  Text(
                    'Canlı yayınlar',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 14,
                    ),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: () => context.go('/live'),
                    child: Text('Tümü'),
                  ),
                ],
              ),
            ),
          if (!embeddedInFeed) SizedBox(height: 10),
          SizedBox(
            height: 118,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: display.length,
              separatorBuilder: (_, _) => SizedBox(width: 16),
              itemBuilder: (ctx, i) => _ActiveRoomChip(
                chip: display[i],
                onTap: () => _openChip(context, ref, display[i]),
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<_ActiveRoomChipData> _buildChips(List<LiveStreamEntity>? streams) {
    final out = <_ActiveRoomChipData>[];
    final ringColors = _ringPalette;

    if (streams != null) {
      var i = 0;
      for (final s in streams.where((x) => x.isLive).take(8)) {
        out.add(
          _ActiveRoomChipData(
            id: s.id,
            kind: _ActiveRoomKind.live,
            name: s.streamerName ?? s.title,
            viewers: s.viewerCount,
            avatarUrl: s.thumbnailUrl,
            ringColor: ringColors[i % ringColors.length],
            liveStream: s,
          ),
        );
        i++;
      }
    }

    return out;
  }

  static List<_ActiveRoomChipData> _demoChips() => [
        _ActiveRoomChipData(
          id: 'demo-1',
          kind: _ActiveRoomKind.demo,
          name: 'Medyum Elif',
          viewers: 1200,
          ringColor: AppThemeColors.accentPurple,
        ),
        _ActiveRoomChipData(
          id: 'demo-2',
          kind: _ActiveRoomKind.demo,
          name: 'Tarot Rüya',
          viewers: 856,
          ringColor: AppThemeColors.liveRed,
        ),
        _ActiveRoomChipData(
          id: 'demo-3',
          kind: _ActiveRoomKind.demo,
          name: 'Astro Ayşe',
          viewers: 642,
          ringColor: AppThemeColors.diamondBlue,
        ),
        _ActiveRoomChipData(
          id: 'demo-4',
          kind: _ActiveRoomKind.demo,
          name: 'Kahve Usta',
          viewers: 410,
          ringColor: AppThemeColors.coinGold,
        ),
        _ActiveRoomChipData(
          id: 'demo-5',
          kind: _ActiveRoomKind.demo,
          name: 'Rüya Yorum',
          viewers: 288,
          ringColor: const Color(0xFFFF8C42),
        ),
      ];

  static const _ringPalette = [
    AppThemeColors.accentPurple,
    AppThemeColors.liveRed,
    AppThemeColors.diamondBlue,
    AppThemeColors.coinGold,
    Color(0xFFFF8C42),
  ];

  void _openChip(
    BuildContext context,
    WidgetRef ref,
    _ActiveRoomChipData chip,
  ) {
    switch (chip.kind) {
      case _ActiveRoomKind.live:
        if (chip.liveStream != null) {
          openLiveStreamNative(context, ref, chip.liveStream!);
        } else {
          context.go('/live');
        }
      case _ActiveRoomKind.demo:
        context.go('/live');
    }
  }
}

enum _ActiveRoomKind { live, demo }

class _ActiveRoomChipData {
  const _ActiveRoomChipData({
    required this.id,
    required this.kind,
    required this.name,
    required this.viewers,
    required this.ringColor,
    this.avatarUrl,
    this.liveStream,
  });

  final String id;
  final _ActiveRoomKind kind;
  final String name;
  final int viewers;
  final Color ringColor;
  final String? avatarUrl;
  final LiveStreamEntity? liveStream;
}

class _ActiveRoomChip extends StatelessWidget {
  const _ActiveRoomChip({required this.chip, required this.onTap});

  final _ActiveRoomChipData chip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 72,
        child: Column(
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: 68,
                  height: 68,
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: chip.ringColor, width: 2.5),
                    boxShadow: AppThemeColors.glowShadow(chip.ringColor, blur: 12),
                  ),
                  child: _Avatar(url: chip.avatarUrl, name: chip.name),
                ),
                Positioned(
                  right: 2,
                  bottom: 2,
                  child: Container(
                    width: 14,
                    height: 14,
                    decoration: BoxDecoration(
                      color: chip.kind == _ActiveRoomKind.live
                          ? AppThemeColors.liveRed
                          : AppThemeColors.accentPurple,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              chip.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: context.colors.onSurface,
              ),
            ),
            Text(
              '${chip.viewers}',
              style: TextStyle(
                fontSize: 10,
                color: context.colors.onSurfaceMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({this.url, required this.name});

  final String? url;
  final String name;

  @override
  Widget build(BuildContext context) {
    if (url != null && url!.isNotEmpty) {
      return ClipOval(
        child: CachedNetworkImage(
          imageUrl: url!,
          width: 56,
          height: 56,
          fit: BoxFit.cover,
          errorWidget: (_, _, _) => const UserAvatar(radius: 28),
        ),
      );
    }
    return const UserAvatar(radius: 28);
  }
}
