import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:canlifal_social/core/theme/app_theme_colors.dart';
import 'package:canlifal_social/core/theme/app_theme_extensions.dart';
import 'package:canlifal_social/core/theme/app_theme_colors.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/widgets/user_avatar.dart';
import '../../../../feed/presentation/widgets/discover/discover_section_header.dart';
import '../../../../live/domain/entities/live_stream_entity.dart';
import '../../../../live/domain/entities/voice_room_entity.dart';
import '../../../../live/presentation/providers/live_providers.dart';
import '../../../../live/presentation/utils/open_live_stream.dart';

/// «Aktif Odalar» — canlı yayın ve ses odaları yatay şeridi.
class SocialActiveRooms extends ConsumerWidget {
  const SocialActiveRooms({super.key, this.embeddedInFeed = false});

  /// Akışta her 2 gönderi arasında gösterilir.
  final bool embeddedInFeed;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final live = ref.watch(liveStreamsProvider);
    final rooms = ref.watch(voiceRoomsProvider);

    final chips = _buildChips(live.valueOrNull, rooms.valueOrNull);
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
              title: 'Aktif Odalar',
              actionLabel: 'Tümünü Gör',
              onAction: () => context.go('/live'),
            )
          else
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
              child: Row(
                children: [
                  Icon(
                    Icons.mic_rounded,
                    size: 18,
                    color: AppThemeColors.accentPurple.withValues(alpha: 0.95),
                  ),
                  SizedBox(width: 8),
                  Text(
                    'Sesli sohbet odaları',
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

  List<_ActiveRoomChipData> _buildChips(
    List<LiveStreamEntity>? streams,
    List<VoiceRoomEntity>? rooms,
  ) {
    final out = <_ActiveRoomChipData>[];
    final ringColors = _ringPalette;

    if (streams != null) {
      var i = 0;
      for (final s in streams.where((x) => x.isLive).take(4)) {
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

    if (rooms != null) {
      var j = out.length;
      for (final r in rooms.take(6 - out.length)) {
        out.add(
          _ActiveRoomChipData(
            id: r.id,
            kind: _ActiveRoomKind.voice,
            name: r.ownerName ?? r.displayTitle,
            viewers: r.displayOnline,
            avatarUrl: r.ownerAvatarUrl ??
                (r.recentUserAvatars.isNotEmpty
                    ? r.recentUserAvatars.first
                    : null),
            ringColor: ringColors[j % ringColors.length],
            voiceRoom: r,
          ),
        );
        j++;
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
      case _ActiveRoomKind.voice:
        if (chip.voiceRoom != null) {
          final room = chip.voiceRoom!;
          context.push('/voice-room/${room.id}', extra: room);
        } else {
          context.push('/voice-rooms');
        }
      case _ActiveRoomKind.demo:
        context.go('/live');
    }
  }
}

enum _ActiveRoomKind { live, voice, demo }

class _ActiveRoomChipData {
  const _ActiveRoomChipData({
    required this.id,
    required this.kind,
    required this.name,
    required this.viewers,
    required this.ringColor,
    this.avatarUrl,
    this.liveStream,
    this.voiceRoom,
  });

  final String id;
  final _ActiveRoomKind kind;
  final String name;
  final int viewers;
  final Color ringColor;
  final String? avatarUrl;
  final LiveStreamEntity? liveStream;
  final VoiceRoomEntity? voiceRoom;
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
                      color: AppThemeColors.onlineGreen,
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
            SizedBox(height: 8),
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
            SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.local_fire_department_rounded,
                  size: 12,
                  color: chip.ringColor.withValues(alpha: 0.95),
                ),
                SizedBox(width: 2),
                Text(
                  _formatViewers(chip.viewers),
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: context.colors.onSurfaceMuted.withValues(alpha: 0.95),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  static String _formatViewers(int n) {
    if (n >= 1000) {
      final k = n / 1000;
      return k >= 10 ? '${k.round()}K' : '${k.toStringAsFixed(1)}K';
    }
    return '$n';
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
          width: 62,
          height: 62,
          fit: BoxFit.cover,
          errorWidget: (_, _, _) => UserAvatar(url: url, radius: 31),
        ),
      );
    }
    return UserAvatar(url: url, radius: 31);
  }
}
