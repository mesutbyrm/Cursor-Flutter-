
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../live/domain/entities/voice_room_entity.dart';
import '../../../domain/entities/chat_room_dj_state.dart';
import '../../../domain/entities/music_queue_item.dart';
import '../../../music/presentation/widgets/room_music_queue_sheet.dart';
import '../../providers/chat_room_providers.dart';
import '../../utils/voice_room_responsive_metrics.dart';
import 'voice_chat_cleared_banner.dart';
import 'voice_room_entry_notification.dart';

/// Kuyruk + giriş bildirimi — mesaj kutusunun hemen üstünde sabit blok.
class VoiceRoomBottomDock extends ConsumerWidget {
  const VoiceRoomBottomDock({
    super.key,
    required this.room,
    required this.session,
    required this.live,
    required this.canControlMusic,
    required this.staffBanner,
  });

  final VoiceRoomEntity room;
  final VoiceRoomEntity session;
  final VoiceRoomLiveState live;
  final bool canControlMusic;
  final String? staffBanner;

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
            if (_waitingQueueItems(live.dj).isNotEmpty)
              GestureDetector(
                onTap: () => showRoomMusicQueueSheet(
                  context,
                  ref,
                  liveKey: session.liveKey,
                  dj: live.dj,
                  canControlMusic: canControlMusic,
                ),
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: m.horizontalPad),
                  child: _QueueStrip(dj: live.dj),
                ),
              ),
            if (live.chatClearedBannerNonce > 0)
              VoiceChatClearedBanner(
                key: ValueKey(live.chatClearedBannerNonce),
              ),
            VoiceRoomEntryNotificationCard(
              message: staffBanner,
              roomName: room.nameTr,
            ),
          ],
        ),
      ),
    );
  }
}

class _QueueStrip extends StatelessWidget {
  const _QueueStrip({required this.dj});

  final ChatRoomDjState dj;

  @override
  Widget build(BuildContext context) {
    final waiting = VoiceRoomBottomDock._waitingQueueItems(dj);
    if (waiting.isEmpty) return const SizedBox.shrink();
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
            child: Text(
              'Sırada ${waiting.length} şarkı',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ),
          const Icon(Icons.chevron_right_rounded, color: Colors.white38, size: 18),
        ],
      ),
    );
  }
}
