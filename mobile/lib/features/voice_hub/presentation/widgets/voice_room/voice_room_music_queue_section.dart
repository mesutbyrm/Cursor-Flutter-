import 'package:flutter/material.dart';
import 'package:canlifal_social/core/theme/app_theme_colors.dart';

import '../../../domain/entities/chat_room_dj_state.dart';
import '../../../domain/entities/music_queue_item.dart';
import '../../theme/voice_room_tokens.dart';
import '../premium/voice_glass.dart';

/// Sıradaki şarkılar — «Şu an çalan» hariç bekleyen parçalar.
class VoiceRoomMusicQueueSection extends StatelessWidget {
  const VoiceRoomMusicQueueSection({
    super.key,
    required this.dj,
    this.coinCost = 10,
    this.maxItems = 4,
  });

  final ChatRoomDjState dj;
  final int coinCost;
  final int maxItems;

  List<MusicQueueItem> _waitingItems() {
    final npId = dj.nowPlaying?.id;
    if (npId == null) {
      if (dj.musicQueue.length <= 1) return const [];
      return dj.musicQueue.sublist(1);
    }
    return dj.musicQueue.where((e) => e.id != npId).toList();
  }

  @override
  Widget build(BuildContext context) {
    final queue = _waitingItems();
    if (queue.isEmpty) return const SizedBox.shrink();

    final visible = queue.take(maxItems).toList();

    return RepaintBoundary(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 0, 12, 6),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 2, bottom: 6),
              child: Text(
                'Sırada (${queue.length})',
                style: const TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 12,
                  color: VoiceRoomTokens.gold,
                ),
              ),
            ),
            ...List.generate(visible.length, (i) {
              final item = visible[i];
              return Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: _QueueRow(
                  index: i + 1,
                  item: item,
                  coinCost: coinCost,
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}

class _QueueRow extends StatelessWidget {
  const _QueueRow({
    required this.index,
    required this.item,
    required this.coinCost,
  });

  final int index;
  final MusicQueueItem item;
  final int coinCost;

  @override
  Widget build(BuildContext context) {
    final artist = item.uploader?.trim().isNotEmpty == true
        ? '${item.uploader} — '
        : '';
    return VoiceGlass(
      borderRadius: 12,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      child: Row(
        children: [
          Text(
            '$index',
            style: const TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: 13,
              color: VoiceRoomTokens.gold,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$artist${item.title}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 11,
                    color: Colors.white,
                  ),
                ),
                Text(
                  'İsteyen: ${item.requestedBy?.displayName ?? '—'}'
                  '${item.duration?.isNotEmpty == true ? ' • ${item.duration}' : ''}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 9,
                    color: Colors.white.withValues(alpha: 0.62),
                  ),
                ),
              ],
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.monetization_on_rounded,
                size: 12,
                color: AppThemeColors.coinGold,
              ),
              const SizedBox(width: 2),
              Text(
                '$coinCost',
                style: const TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 10,
                  color: AppThemeColors.coinGold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
