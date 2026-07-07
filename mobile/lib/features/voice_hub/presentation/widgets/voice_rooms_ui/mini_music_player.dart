import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/chat_room_providers.dart';
import 'voice_rooms_mock_data.dart';
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
    final session = ref.watch(voiceRoomMusicSessionProvider);
    final hasLive = session.hasActiveMusic && session.room != null;
    final room = session.room;
    final dj = session.dj;
    final nowPlaying = dj.nowPlaying;

    final title = hasLive ? room!.displayTitle : VoiceRoomsMockData.musicTitle;
    final artist = hasLive
        ? (nowPlaying?.requestedBy?.name.trim().isNotEmpty == true
            ? '${nowPlaying!.requestedBy!.name} çalıyor'
            : VoiceRoomsMockData.musicArtist)
        : VoiceRoomsMockData.musicArtist;
    final track = hasLive
        ? (nowPlaying?.title.trim().isNotEmpty == true
            ? nowPlaying!.title
            : VoiceRoomsMockData.musicTrack)
        : VoiceRoomsMockData.musicTrack;
    final playing = hasLive ? dj.playing : true;

    final bottom = MediaQuery.paddingOf(context).bottom;
    return AnimatedContainer(
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
          Hero(
            tag: 'mini_player_art',
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                gradient: VoiceRoomsUiTokens.purpleGradient,
                boxShadow: VoiceRoomsUiTokens.glowShadow(
                  VoiceRoomsUiTokens.purpleGlow,
                  blur: 12,
                ),
                image: nowPlaying?.thumbUrl?.trim().isNotEmpty == true
                    ? DecorationImage(
                        image: NetworkImage(nowPlaying!.thumbUrl!),
                        fit: BoxFit.cover,
                      )
                    : null,
              ),
              alignment: Alignment.center,
              child: nowPlaying?.thumbUrl?.trim().isNotEmpty == true
                  ? null
                  : VoiceRoomsSvgIcons.icon('music', size: 18, color: Colors.white),
            ),
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
                    '$title — $artist',
                    style: const TextStyle(
                      color: VoiceRoomsUiTokens.textPrimary,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    track,
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
              if (!hasLive || room == null) return;
              final ctrl = ref.read(voiceRoomLiveProvider(room.liveKey).notifier);
              if (dj.playing) {
                await ctrl.pauseMusic();
              } else {
                await ctrl.resumeMusic();
              }
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: VoiceRoomsUiTokens.purpleGradient,
                boxShadow: VoiceRoomsUiTokens.purpleGlowShadow(blur: 12),
              ),
              child: Center(
                child: VoiceRoomsSvgIcons.icon(
                  playing ? 'play' : 'play',
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
              onTap: () {},
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
    );
  }
}
