import 'dart:async';

import 'package:flutter/material.dart';
import 'package:canlifal_social/core/theme/app_theme_colors.dart';
import 'package:canlifal_social/core/theme/app_theme_extensions.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:canlifal_social/core/images/canlifal_network_image.dart';

import '../../../../../core/widgets/user_avatar.dart';
import '../../../../feed/presentation/widgets/discover/discover_section_header.dart';
import '../../../../live/domain/entities/live_stream_entity.dart';
import '../../../../live/domain/entities/voice_room_entity.dart';
import '../../../../live/presentation/providers/live_providers.dart';
import '../../../../live/presentation/utils/open_live_stream.dart';
import '../../../../voice_hub/presentation/providers/voice_rooms_presence_provider.dart';
import '../../../../voice_hub/presentation/utils/navigate_to_voice_room.dart';
import '../../utils/social_feed_refresh.dart';

/// «Aktif Odalar» — canlı yayın ve ses odaları yatay şeridi.
class SocialActiveRooms extends ConsumerWidget {
  const SocialActiveRooms({super.key, this.embeddedInFeed = false});

  /// Akışta her 2 gönderi arasında gösterilir.
  final bool embeddedInFeed;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final live = ref.watch(liveStreamsProvider);
    final rooms = ref.watch(voiceRoomsProvider);
    final presence = ref.watch(voiceRoomsPresenceProvider);

    final chips = _buildChips(
      live.valueOrNull,
      rooms.valueOrNull,
      presence,
    );
    final hasLive = chips.any((c) => c.kind == _ActiveRoomKind.live);
    final hasVoice = chips.any((c) => c.kind == _ActiveRoomKind.voice);
    final embeddedTitle = buildSocialActiveRoomsEmbeddedTitle(
      hasLive: hasLive,
      hasVoice: hasVoice,
    );
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

    if (chips.isEmpty) {
      return const SizedBox.shrink();
    }

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
                    embeddedTitle,
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 14,
                    ),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: () => context.go('/voice-rooms'),
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
              itemCount: chips.length,
              separatorBuilder: (_, _) => SizedBox(width: 16),
              itemBuilder: (ctx, i) => _ActiveRoomChip(
                chip: chips[i],
                onTap: () => _openChip(context, ref, chips[i]),
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
    VoiceRoomsPresenceState presence,
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
            isActive: s.viewerCount > 0,
          ),
        );
        i++;
      }
    }

    if (rooms != null) {
      final voiceRooms = [...rooms]
        ..sort((a, b) {
          final aCount = _voiceOnline(a, presence);
          final bCount = _voiceOnline(b, presence);
          return bCount.compareTo(aCount);
        });
      var j = out.length;
      for (final r in voiceRooms.take(8 - out.length)) {
        final online = _voiceOnline(r, presence);
        out.add(
          _ActiveRoomChipData(
            id: r.id,
            kind: _ActiveRoomKind.voice,
            name: r.ownerName ?? r.displayTitle,
            viewers: online,
            avatarUrl: r.ownerAvatarUrl ??
                (r.recentUserAvatars.isNotEmpty
                    ? r.recentUserAvatars.first
                    : null),
            ringColor: ringColors[j % ringColors.length],
            voiceRoom: r,
            isActive: online > 0,
            isPkLive: r.isPkLive,
            isMusicPlaying: r.hasMusicActivity,
          ),
        );
        j++;
      }
    }

    return out;
  }

  static int _voiceOnline(VoiceRoomEntity room, VoiceRoomsPresenceState presence) {
    final sse = presence.countFor(room);
    final api = room.displayOnline;
    return sse > api ? sse : api;
  }

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
          unawaited(
            navigateToVoiceRoom(
              context,
              ref,
              room: chip.voiceRoom!,
              source: 'social_active',
            ),
          );
        } else {
          context.push('/voice-rooms');
        }
    }
  }
}

enum _ActiveRoomKind { live, voice }

class _ActiveRoomChipData {
  const _ActiveRoomChipData({
    required this.id,
    required this.kind,
    required this.name,
    required this.viewers,
    required this.ringColor,
    required this.isActive,
    this.avatarUrl,
    this.liveStream,
    this.voiceRoom,
    this.isPkLive = false,
    this.isMusicPlaying = false,
  });

  final String id;
  final _ActiveRoomKind kind;
  final String name;
  final int viewers;
  final Color ringColor;
  final bool isActive;
  final String? avatarUrl;
  final LiveStreamEntity? liveStream;
  final VoiceRoomEntity? voiceRoom;
  final bool isPkLive;
  final bool isMusicPlaying;
}

class _ActiveRoomChip extends StatefulWidget {
  const _ActiveRoomChip({required this.chip, required this.onTap});

  final _ActiveRoomChipData chip;
  final VoidCallback onTap;

  @override
  State<_ActiveRoomChip> createState() => _ActiveRoomChipState();
}

class _ActiveRoomChipState extends State<_ActiveRoomChip>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseCtrl;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );
    if (widget.chip.isActive) {
      _pulseCtrl.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(covariant _ActiveRoomChip oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.chip.isActive && !_pulseCtrl.isAnimating) {
      _pulseCtrl.repeat(reverse: true);
    } else if (!widget.chip.isActive && _pulseCtrl.isAnimating) {
      _pulseCtrl.stop();
      _pulseCtrl.value = 0;
    }
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final chip = widget.chip;
    final isActive = chip.isActive;
    final ringColor = isActive
        ? chip.ringColor
        : chip.ringColor.withValues(alpha: 0.28);

    return GestureDetector(
      onTap: widget.onTap,
      child: Opacity(
        opacity: isActive ? 1 : 0.42,
        child: SizedBox(
          width: 72,
          child: Column(
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  AnimatedBuilder(
                    animation: _pulseCtrl,
                    builder: (context, _) {
                      final glow =
                          isActive ? 8 + (_pulseCtrl.value * 10) : 0.0;
                      return Container(
                        width: 68,
                        height: 68,
                        padding: const EdgeInsets.all(3),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: ringColor,
                            width: isActive ? 2.5 : 1.5,
                          ),
                          boxShadow: isActive
                              ? AppThemeColors.glowShadow(
                                  chip.ringColor,
                                  blur: glow,
                                )
                              : null,
                        ),
                        child: _Avatar(url: chip.avatarUrl, name: chip.name),
                      );
                    },
                  ),
                  if (isActive)
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
                  if (chip.isPkLive && isActive)
                    Positioned(
                      left: -2,
                      top: -2,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 5,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFF5252),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          'PK',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 8,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ),
                  if (chip.isMusicPlaying && isActive)
                    Positioned(
                      right: -2,
                      top: -2,
                      child: Icon(
                        Icons.music_note_rounded,
                        size: 14,
                        color: const Color(0xFFFFD54F)
                            .withValues(alpha: 0.95),
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
                  color: isActive
                      ? context.colors.onSurface
                      : context.colors.onSurfaceMuted,
                ),
              ),
              SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    isActive
                        ? Icons.local_fire_department_rounded
                        : Icons.mic_none_rounded,
                    size: 12,
                    color: ringColor.withValues(alpha: isActive ? 0.95 : 0.5),
                  ),
                  SizedBox(width: 2),
                  Text(
                    isActive ? _formatViewers(chip.viewers) : 'Boş',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: context.colors.onSurfaceMuted
                          .withValues(alpha: isActive ? 0.95 : 0.55),
                    ),
                  ),
                ],
              ),
            ],
          ),
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
        child: CanlifalNetworkImage(
          url: url!,
          width: 62,
          height: 62,
          fit: BoxFit.cover,
          errorWidget: UserAvatar(url: url, radius: 31),
        ),
      );
    }
    return UserAvatar(url: url, radius: 31);
  }
}
