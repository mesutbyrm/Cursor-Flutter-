import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../live/domain/entities/voice_room_entity.dart';
import '../../providers/chat_room_providers.dart';
import '../../providers/room_fragment_providers.dart';
import '../../../music/presentation/widgets/room_music_queue_sheet.dart';
import '../voice_room/voice_room_music_request_flash.dart';
import '../../../domain/entities/chat_room_dj_state.dart';
import '../../../domain/entities/music_queue_item.dart';

/// Koltukların hemen altında tam genişlik — !istek / SSE müzik özeti (video yok).
class VoiceRoomCenterMusicPanel extends ConsumerWidget {
  const VoiceRoomCenterMusicPanel({
    super.key,
    required this.room,
    required this.liveRoomKey,
    required this.canControlMusic,
    required this.canCloseMusic,
  });

  final VoiceRoomEntity room;
  final String liveRoomKey;
  final bool canControlMusic;
  final bool canCloseMusic;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dj = ref.watch(voiceRoomMusicSliceProvider(liveRoomKey));
    final flash = ref.watch(
      voiceRoomLiveProvider(liveRoomKey).select((s) => s.musicRequestFlash),
    );
    final listenerCount = ref.watch(
      voiceRoomLiveProvider(liveRoomKey).select((s) => s.onlineCountFor(room)),
    );
    final musicSession = ref.watch(voiceRoomMusicSessionProvider);
    final sessionKey = room.apiRoomKey.isNotEmpty ? room.apiRoomKey : room.id;

    final hasTrack =
        dj.playing || dj.nowPlaying != null || dj.musicQueue.isNotEmpty;
    final showPlayer = hasTrack &&
        !musicSession.dismissed &&
        !musicSession.userDismissedPlayer;

    if (!showPlayer && (flash == null || flash.trim().isEmpty)) {
      return const SizedBox.shrink();
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (flash != null && flash.trim().isNotEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: VoiceRoomMusicRequestFlash(message: flash),
          ),
        if (showPlayer)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: _AudioMusicSummary(
              dj: dj,
              listenerCount: listenerCount,
              onQueueTap: () => showRoomMusicQueueSheet(
                context,
                ref,
                liveKey: sessionKey,
                dj: dj,
                canControlMusic: canControlMusic,
                canStopMusic: canCloseMusic,
              ),
            ),
          ),
      ],
    );
  }
}

class _AudioMusicSummary extends StatelessWidget {
  const _AudioMusicSummary({
    required this.dj,
    required this.listenerCount,
    required this.onQueueTap,
  });

  final ChatRoomDjState dj;
  final int listenerCount;
  final VoidCallback onQueueTap;

  List<MusicQueueItem> get _waiting {
    final npId = dj.nowPlaying?.id;
    if (npId == null) {
      if (dj.musicQueue.length <= 1) return const [];
      return dj.musicQueue.sublist(1);
    }
    return dj.musicQueue.where((e) => e.id != npId).toList();
  }

  @override
  Widget build(BuildContext context) {
    final now = dj.nowPlaying;
    final waiting = _waiting;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (now != null)
          Container(
            margin: const EdgeInsets.only(top: 4, bottom: 4),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFF7C3AED).withValues(alpha: 0.28),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
            ),
            child: Row(
              children: [
                Icon(
                  dj.playing
                      ? Icons.graphic_eq_rounded
                      : Icons.music_note_rounded,
                  color: Colors.white70,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        now.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 12,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        [
                          if (now.requesterLabel != null)
                            'İsteyen: ${now.requesterLabel}',
                          '$listenerCount dinleyici',
                        ].join(' · '),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.white.withValues(alpha: 0.7),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        if (waiting.isNotEmpty)
          GestureDetector(
            onTap: onQueueTap,
            child: Container(
              margin: const EdgeInsets.only(bottom: 4),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.queue_music_rounded,
                      color: Colors.white70, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Sırada: ${waiting.first.title}'
                      '${waiting.first.requesterLabel != null ? ' (${waiting.first.requesterLabel})' : ''}'
                      '${waiting.length > 1 ? ' +${waiting.length - 1}' : ''}',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const Icon(Icons.chevron_right_rounded,
                      color: Colors.white38, size: 18),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
