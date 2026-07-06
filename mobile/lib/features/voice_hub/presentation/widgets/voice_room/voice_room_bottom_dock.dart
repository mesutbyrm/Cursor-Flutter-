
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../live/domain/entities/voice_room_entity.dart';
import '../../../domain/entities/chat_room_dj_state.dart';
import '../../../domain/entities/music_queue_item.dart';
import '../../../music/presentation/widgets/room_music_queue_sheet.dart';
import '../../providers/chat_room_providers.dart';
import '../../utils/voice_room_responsive_metrics.dart';
import 'voice_chat_cleared_banner.dart';
import 'voice_room_music_request_flash.dart';

/// Kuyruk + çalan parça + istek duyurusu — mesaj kutusunun hemen üstünde sabit blok.
class VoiceRoomBottomDock extends ConsumerWidget {
  const VoiceRoomBottomDock({
    super.key,
    required this.room,
    required this.session,
    required this.live,
    required this.canControlMusic,
    required this.canStopMusic,
  });

  final VoiceRoomEntity room;
  final VoiceRoomEntity session;
  final VoiceRoomLiveState live;
  final bool canControlMusic;
  final bool canStopMusic;

  static List<MusicQueueItem> _waitingQueueItems(ChatRoomDjState dj) {
    final npId = dj.nowPlaying?.id;
    if (npId == null) {
      if (dj.musicQueue.length <= 1) return const [];
      return dj.musicQueue.sublist(1);
    }
    return dj.musicQueue.where((e) => e.id != npId).toList();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final m = VoiceRoomResponsiveMetrics.of(context);
    final dj = live.dj;
    final waiting = _waitingQueueItems(dj);
    final now = dj.nowPlaying;
    final flash = live.musicRequestFlash;

    return RepaintBoundary(
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.transparent,
              Colors.black.withValues(alpha: 0.55),
            ],
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (flash != null && flash.trim().isNotEmpty)
              Padding(
                padding: EdgeInsets.fromLTRB(m.horizontalPad, 0, m.horizontalPad, 4),
                child: VoiceRoomMusicRequestFlash(message: flash),
              ),
            if (now != null || dj.playing)
              Padding(
                padding: EdgeInsets.symmetric(horizontal: m.horizontalPad),
                child: _NowPlayingStrip(track: now, playing: dj.playing),
              ),
            if (waiting.isNotEmpty)
              GestureDetector(
                onTap: () => showRoomMusicQueueSheet(
                  context,
                  ref,
                  liveKey: session.liveKey,
                  dj: live.dj,
                  canControlMusic: canControlMusic,
                  canStopMusic: canStopMusic,
                ),
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: m.horizontalPad),
                  child: _QueueStrip(waiting: waiting),
                ),
              ),
            if (live.chatClearedBannerNonce > 0)
              VoiceChatClearedBanner(
                key: ValueKey(live.chatClearedBannerNonce),
              ),
          ],
        ),
      ),
    );
  }
}

class _NowPlayingStrip extends StatelessWidget {
  const _NowPlayingStrip({required this.track, required this.playing});

  final MusicQueueItem? track;
  final bool playing;

  @override
  Widget build(BuildContext context) {
    final title = track?.title.trim();
    if (title == null || title.isEmpty) return const SizedBox.shrink();
    final who = track?.requesterLabel;
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: const Color(0xFF7C3AED).withValues(alpha: 0.28),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
      ),
      child: Row(
        children: [
          Icon(
            playing ? Icons.graphic_eq_rounded : Icons.music_note_rounded,
            color: Colors.white.withValues(alpha: 0.9),
            size: 18,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
                if (who != null)
                  Text(
                    'İsteyen: $who',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.white.withValues(alpha: 0.72),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _QueueStrip extends StatelessWidget {
  const _QueueStrip({required this.waiting});

  final List<MusicQueueItem> waiting;

  @override
  Widget build(BuildContext context) {
    if (waiting.isEmpty) return const SizedBox.shrink();
    final next = waiting.first;
    final who = next.requesterLabel;
    final more = waiting.length - 1;
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
      ),
      child: Row(
        children: [
          const Icon(Icons.queue_music_rounded, color: Colors.white70, size: 16),
          const SizedBox(width: 6),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Sırada: ${next.title}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                Text(
                  [
                    if (who != null) 'İsteyen: $who',
                    if (more > 0) '+$more şarkı daha',
                  ].join(' · '),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.white.withValues(alpha: 0.65),
                  ),
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right_rounded, color: Colors.white38, size: 18),
        ],
      ),
    );
  }
}
