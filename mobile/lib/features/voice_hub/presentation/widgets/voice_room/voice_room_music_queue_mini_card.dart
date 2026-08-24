import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/entities/chat_room_dj_state.dart';
import '../../../domain/entities/music_queue_item.dart';
import '../../../music/presentation/widgets/room_music_queue_sheet.dart';
import '../../theme/voice_room_tokens.dart';

/// Sağ alt — sıradaki ilk 3 istek (kompakt kart).
class VoiceRoomMusicQueueMiniCard extends ConsumerWidget {
  const VoiceRoomMusicQueueMiniCard({
    super.key,
    required this.dj,
    required this.liveKey,
    required this.canControlMusic,
    required this.canStopMusic,
    this.maxItems = 3,
  });

  final ChatRoomDjState dj;
  final String liveKey;
  final bool canControlMusic;
  final bool canStopMusic;
  final int maxItems;

  static List<MusicQueueItem> waitingItems(ChatRoomDjState dj) {
    final npId = dj.nowPlaying?.id;
    if (npId == null) {
      if (dj.musicQueue.length <= 1) return const [];
      return dj.musicQueue.sublist(1);
    }
    return dj.musicQueue.where((e) => e.id != npId).toList();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final waiting = waitingItems(dj);
    if (waiting.isEmpty) return const SizedBox.shrink();

    final visible = waiting.take(maxItems).toList();
    final more = waiting.length - visible.length;

    return RepaintBoundary(
      child: GestureDetector(
        onTap: () => showRoomMusicQueueSheet(
          context,
          ref,
          liveKey: liveKey,
          dj: dj,
          canControlMusic: canControlMusic,
          canStopMusic: canStopMusic,
        ),
        child: Container(
          width: 168,
          padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.72),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: VoiceRoomTokens.neonPurple.withValues(alpha: 0.45),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.35),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.queue_music_rounded,
                    size: 14,
                    color: VoiceRoomTokens.gold,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Sıra (${waiting.length})',
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      color: VoiceRoomTokens.gold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              ...visible.map((item) {
                final idx = waiting.indexOf(item) + 1;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: _MiniRow(index: idx, item: item),
                );
              }),
              if (more > 0)
                Text(
                  '+$more daha…',
                  style: TextStyle(
                    fontSize: 9,
                    color: Colors.white.withValues(alpha: 0.55),
                    fontWeight: FontWeight.w600,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MiniRow extends StatelessWidget {
  const _MiniRow({required this.index, required this.item});

  final int index;
  final MusicQueueItem item;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          '$index',
          style: TextStyle(
            fontSize: 9,
            fontWeight: FontWeight.w900,
            color: Colors.white.withValues(alpha: 0.5),
          ),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            item.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
        ),
      ],
    );
  }
}
