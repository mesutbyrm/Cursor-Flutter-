
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../live/domain/entities/voice_room_entity.dart';
import '../../../domain/entities/chat_room_dj_state.dart';
import '../../../domain/entities/music_queue_item.dart';
import '../../../music/presentation/widgets/room_music_queue_sheet.dart';
import '../../providers/chat_room_providers.dart';
import '../../providers/room_fragment_providers.dart';
import '../../providers/voice_room_ui_provider.dart';
import '../../utils/voice_room_responsive_metrics.dart';
import 'voice_chat_cleared_banner.dart';
import 'voice_room_music_request_flash.dart';
import 'voice_room_web_music_bar.dart';

/// Kuyruk + tam müzik oynatıcı — mesaj kutusunun hemen üstünde sabit blok.
class VoiceRoomBottomDock extends ConsumerWidget {
  const VoiceRoomBottomDock({
    super.key,
    required this.room,
    required this.session,
    required this.canControlMusic,
    required this.canStopMusic,
  });

  final VoiceRoomEntity room;
  final VoiceRoomEntity session;
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
    final liveKey = session.liveKey;
    final dj = ref.watch(voiceRoomMusicSliceProvider(liveKey));
    final flash = ref.watch(
      voiceRoomLiveProvider(liveKey).select((s) => s.musicRequestFlash),
    );
    final chatClearedNonce = ref.watch(
      voiceRoomLiveProvider(liveKey).select((s) => s.chatClearedBannerNonce),
    );
    final waiting = _waitingQueueItems(dj);
    final ctrl = ref.read(voiceRoomLiveProvider(liveKey).notifier);
    final ui = ref.watch(voiceRoomUiProvider);
    final hasPlayer = dj.nowPlaying != null || dj.playing;

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
            if (hasPlayer)
              VoiceRoomWebMusicBar(
                dj: dj,
                roomLiveKey: liveKey,
                isVideoMode: dj.nowPlaying?.isVideoRequest == true,
                musicMuted: !ui.backgroundMusicEnabled,
                canControlMusic: canControlMusic,
                onPlayPause: () async {
                  if (dj.playing) {
                    await ctrl.pauseMusic();
                  } else {
                    await ctrl.resumeMusic();
                  }
                },
                onStop: () async {
                  await ctrl.closeMusicPlayer();
                },
                onClose: () async {
                  await ctrl.closeMusicPlayer();
                },
                onSkipNext: canControlMusic
                    ? () async {
                        await ctrl.skipMusic();
                      }
                    : null,
                onMuteToggle: () {
                  ref.read(voiceRoomUiProvider.notifier).toggleBackgroundMusic();
                },
                onQueueTap: waiting.isNotEmpty
                    ? () => showRoomMusicQueueSheet(
                          context,
                          ref,
                          liveKey: liveKey,
                          dj: dj,
                          canControlMusic: canControlMusic,
                          canStopMusic: canStopMusic,
                        )
                    : null,
              ),
            if (waiting.isNotEmpty && !hasPlayer)
              GestureDetector(
                onTap: () => showRoomMusicQueueSheet(
                  context,
                  ref,
                  liveKey: liveKey,
                  dj: dj,
                  canControlMusic: canControlMusic,
                  canStopMusic: canStopMusic,
                ),
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: m.horizontalPad),
                  child: _QueueStrip(waiting: waiting),
                ),
              ),
            if (chatClearedNonce > 0)
              VoiceChatClearedBanner(
                key: ValueKey(chatClearedNonce),
              ),
          ],
        ),
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
