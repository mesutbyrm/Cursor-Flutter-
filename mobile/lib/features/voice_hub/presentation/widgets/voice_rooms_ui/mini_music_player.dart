import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/images/canlifal_network_image.dart';
import '../../../music/presentation/widgets/room_music_queue_sheet.dart';
import '../../providers/chat_room_providers.dart';
import 'voice_rooms_hero.dart';
import 'voice_rooms_svg_icons.dart';
import 'voice_rooms_ui_tokens.dart';

class MiniMusicPlayer extends ConsumerStatefulWidget {
  const MiniMusicPlayer({super.key});

  @override
  ConsumerState<MiniMusicPlayer> createState() => _MiniMusicPlayerState();
}

class _MiniMusicPlayerState extends ConsumerState<MiniMusicPlayer> {
  var _expanded = true;
  var _liked = false;

  @override
  Widget build(BuildContext context) {
    final view = ref.watch(
      voiceRoomMusicSessionProvider.select((session) {
        final hasLive = session.hasActiveMusic && session.room != null;
        final room = session.room;
        final dj = session.dj;
        final nowPlaying = dj.nowPlaying;
        return (
          hasLive: hasLive,
          title: hasLive ? room!.displayTitle : '',
          artist: hasLive
              ? (nowPlaying?.requestedBy?.name.trim().isNotEmpty == true
                  ? '${nowPlaying!.requestedBy!.name} çalıyor'
                  : 'Canlı DJ')
              : '',
          track: hasLive
              ? (nowPlaying?.title.trim().isNotEmpty == true
                  ? nowPlaying!.title
                  : 'Çalıyor')
              : '',
          playing: hasLive ? dj.playing : false,
          thumbUrl: nowPlaying?.thumbUrl,
          roomLiveKey: hasLive ? room!.liveKey : null,
          room: room,
          dj: dj,
        );
      }),
    );

    if (!view.hasLive || view.roomLiveKey == null || view.room == null) {
      return const SizedBox.shrink();
    }

    final bottom = MediaQuery.paddingOf(context).bottom;
    return RepaintBoundary(
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOutCubic,
        margin: EdgeInsets.fromLTRB(12, 0, 12, bottom + 72),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(VoiceRoomsUiTokens.radiusLg),
          color: const Color(0xFF121212).withValues(alpha: 0.92),
          border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
          boxShadow: [
            ...VoiceRoomsUiTokens.purpleGlowShadow(blur: 20),
            const BoxShadow(
              color: Color(0x66000000),
              blurRadius: 16,
              offset: Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => setState(() => _expanded = !_expanded),
                customBorder: const CircleBorder(),
                child: Padding(
                  padding: const EdgeInsets.all(4),
                  child: AnimatedRotation(
                    turns: _expanded ? 0 : 0.5,
                    duration: const Duration(milliseconds: 220),
                    child: VoiceRoomsSvgIcons.icon(
                      'chevron_down',
                      size: 18,
                      color: VoiceRoomsUiTokens.textSecondary,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 6),
            VoiceRoomsHero(
              tag: 'mini_player_art',
              child: _Artwork(thumbUrl: view.thumbUrl),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: AnimatedOpacity(
                opacity: _expanded ? 1 : 0,
                duration: const Duration(milliseconds: 200),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${view.title} — ${view.artist}',
                      style: const TextStyle(
                        color: VoiceRoomsUiTokens.textPrimary,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      view.track,
                      style: const TextStyle(
                        color: VoiceRoomsUiTokens.textMuted,
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => setState(() => _liked = !_liked),
                customBorder: const CircleBorder(),
                child: Padding(
                  padding: const EdgeInsets.all(6),
                  child: AnimatedScale(
                    scale: _liked ? 1.15 : 1.0,
                    duration: const Duration(milliseconds: 180),
                    child: VoiceRoomsSvgIcons.icon(
                      'heart',
                      size: 18,
                      color: _liked
                          ? VoiceRoomsUiTokens.coral
                          : VoiceRoomsUiTokens.textSecondary,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 4),
            GestureDetector(
              onTap: () async {
                final liveKey = view.roomLiveKey;
                if (!view.hasLive || liveKey == null) return;
                final ctrl =
                    ref.read(voiceRoomLiveProvider(liveKey).notifier);
                if (view.playing) {
                  await ctrl.pauseMusic();
                } else {
                  await ctrl.resumeMusic();
                }
              },
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: VoiceRoomsUiTokens.purpleGradient,
                  boxShadow: VoiceRoomsUiTokens.purpleGlowShadow(blur: 12),
                ),
                child: Center(
                  child: VoiceRoomsSvgIcons.icon(
                    'play',
                    size: 18,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 4),
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {
                  final liveKey = view.roomLiveKey;
                  if (liveKey == null) return;
                  showRoomMusicQueueSheet(
                    context,
                    ref,
                    liveKey: liveKey,
                    dj: view.dj,
                    canControlMusic: false,
                  );
                },
                customBorder: const CircleBorder(),
                child: Padding(
                  padding: const EdgeInsets.all(6),
                  child: VoiceRoomsSvgIcons.icon(
                    'playlist',
                    size: 18,
                    color: VoiceRoomsUiTokens.textSecondary,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Artwork extends StatelessWidget {
  const _Artwork({this.thumbUrl});

  final String? thumbUrl;

  @override
  Widget build(BuildContext context) {
    final url = thumbUrl?.trim();
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        gradient: VoiceRoomsUiTokens.purpleGradient,
        boxShadow: VoiceRoomsUiTokens.glowShadow(
          VoiceRoomsUiTokens.purpleGlow,
          blur: 12,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      alignment: Alignment.center,
      child: url != null && url.isNotEmpty
          ? CanlifalNetworkImage(
              url: url,
              width: 40,
              height: 40,
              fit: BoxFit.cover,
              thumbnailWidth: 80,
              fadeIn: false,
            )
          : VoiceRoomsSvgIcons.icon('music', size: 18, color: Colors.white),
    );
  }
}
