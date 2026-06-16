import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/entities/chat_room_dj_state.dart';
import '../../../domain/entities/music_queue_item.dart';
import '../../../presentation/providers/chat_room_providers.dart';
import '../../../presentation/theme/voice_room_tokens.dart';
import '../../../presentation/widgets/premium/voice_glass.dart';

/// Tam müzik kuyruğu — DJ silme / sıra görünümü.
Future<void> showRoomMusicQueueSheet(
  BuildContext context,
  WidgetRef ref, {
  required String liveKey,
  required ChatRoomDjState dj,
  required bool canControlMusic,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: const Color(0xFF12121A),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (ctx) => _RoomMusicQueueSheet(
      liveKey: liveKey,
      dj: dj,
      canControlMusic: canControlMusic,
    ),
  );
}

class _RoomMusicQueueSheet extends ConsumerWidget {
  const _RoomMusicQueueSheet({
    required this.liveKey,
    required this.dj,
    required this.canControlMusic,
  });

  final String liveKey;
  final ChatRoomDjState dj;
  final bool canControlMusic;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bottom = MediaQuery.paddingOf(context).bottom;
    final ctrl = ref.read(voiceRoomLiveProvider(liveKey).notifier);
    final queue = dj.musicQueue;
    final nowId = dj.nowPlaying?.id;

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.65,
      minChildSize: 0.4,
      maxChildSize: 0.9,
      builder: (context, scrollController) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 8),
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 12, 8),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Müzik kuyruğu (${queue.length})',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close_rounded, color: Colors.white70),
                  ),
                ],
              ),
            ),
            Expanded(
              child: queue.isEmpty
                  ? const Center(
                      child: Text(
                        'Kuyruk boş',
                        style: TextStyle(color: Colors.white60),
                      ),
                    )
                  : ListView.separated(
                      controller: scrollController,
                      padding: EdgeInsets.fromLTRB(16, 0, 16, bottom + 16),
                      itemCount: queue.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (context, i) {
                        final item = queue[i];
                        final isNow = item.id == nowId;
                        return _QueueTile(
                          index: i + 1,
                          item: item,
                          isNowPlaying: isNow,
                          canRemove: canControlMusic && !isNow,
                          onRemove: () async {
                            final err = await ctrl.removeQueueItem(item.id);
                            if (context.mounted && err != null) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text(err)),
                              );
                            }
                          },
                        );
                      },
                    ),
            ),
          ],
        );
      },
    );
  }
}

class _QueueTile extends StatelessWidget {
  const _QueueTile({
    required this.index,
    required this.item,
    required this.isNowPlaying,
    required this.canRemove,
    required this.onRemove,
  });

  final int index;
  final MusicQueueItem item;
  final bool isNowPlaying;
  final bool canRemove;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final requester = item.requestedBy?.displayName ?? '—';
    return VoiceGlass(
      borderRadius: 14,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        children: [
          Text(
            '$index',
            style: TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: 14,
              color: isNowPlaying ? VoiceRoomTokens.gold : Colors.white54,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
                Text(
                  '${item.uploader ?? item.artistLine.split(' • ').firstOrNull ?? '—'} • $requester'
                  '${item.duration?.isNotEmpty == true ? ' • ${item.duration}' : ''}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.white.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
          ),
          if (isNowPlaying)
            Padding(
              padding: const EdgeInsets.only(left: 8),
              child: Icon(
                Icons.equalizer_rounded,
                color: VoiceRoomTokens.gold,
                size: 20,
              ),
            ),
          if (canRemove)
            IconButton(
              onPressed: onRemove,
              icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent),
              tooltip: 'Kuyruktan sil',
            ),
        ],
      ),
    );
  }
}

extension _FirstOrNull<E> on Iterable<E> {
  E? get firstOrNull {
    final it = iterator;
    if (!it.moveNext()) return null;
    return it.current;
  }
}
