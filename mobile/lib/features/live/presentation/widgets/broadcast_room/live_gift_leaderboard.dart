import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/live_gift_leaderboard_provider.dart';

/// Canlı yayın hediye sıralaması — sol alt köşe.
class LiveGiftLeaderboard extends ConsumerStatefulWidget {
  const LiveGiftLeaderboard({
    super.key,
    required this.streamId,
  });

  final String streamId;

  @override
  ConsumerState<LiveGiftLeaderboard> createState() =>
      _LiveGiftLeaderboardState();
}

class _LiveGiftLeaderboardState extends ConsumerState<LiveGiftLeaderboard> {
  var _expanded = false;

  @override
  Widget build(BuildContext context) {
    final senders = ref.watch(liveGiftLeaderboardProvider(widget.streamId));

    if (senders.isEmpty) return const SizedBox.shrink();

    final visible = _expanded ? senders : senders.take(3).toList();
    final hasMore = senders.length > 3;

    return Container(
      width: 220,
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.card_giftcard_rounded, color: Colors.amber, size: 16),
              const SizedBox(width: 6),
              const Text(
                'Hediye Atanlar',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              Text(
                '${senders.length} kişi',
                style: const TextStyle(color: Colors.white54, fontSize: 11),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...visible.asMap().entries.map(
                (entry) => _GiftSenderRow(
                  rank: entry.key + 1,
                  sender: entry.value,
                ),
              ),
          if (hasMore) ...[
            const SizedBox(height: 4),
            GestureDetector(
              onTap: () => setState(() => _expanded = !_expanded),
              child: Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _expanded
                          ? 'Daha az göster'
                          : '+${senders.length - 3} kişi daha',
                      style: const TextStyle(
                        color: Colors.amber,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      _expanded
                          ? Icons.keyboard_arrow_up_rounded
                          : Icons.keyboard_arrow_down_rounded,
                      color: Colors.amber,
                      size: 16,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _GiftSenderRow extends StatelessWidget {
  const _GiftSenderRow({
    required this.rank,
    required this.sender,
  });

  final int rank;
  final LiveGiftSender sender;

  @override
  Widget build(BuildContext context) {
    final initial = sender.username.isNotEmpty
        ? sender.username[0].toUpperCase()
        : '?';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 22,
            child: rank <= 3
                ? Text(
                    rank == 1
                        ? '🥇'
                        : rank == 2
                            ? '🥈'
                            : '🥉',
                    style: const TextStyle(fontSize: 14),
                  )
                : Text(
                    '$rank',
                    style: const TextStyle(color: Colors.white54, fontSize: 11),
                  ),
          ),
          CircleAvatar(
            radius: 14,
            backgroundImage: sender.avatarUrl != null && sender.avatarUrl!.isNotEmpty
                ? NetworkImage(sender.avatarUrl!)
                : null,
            backgroundColor: const Color(0xFF6C3FC5),
            child: sender.avatarUrl == null || sender.avatarUrl!.isEmpty
                ? Text(
                    initial,
                    style: const TextStyle(color: Colors.white, fontSize: 10),
                  )
                : null,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  sender.username,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  '${sender.giftEmoji} ${sender.giftName} x${sender.giftCount}',
                  style: const TextStyle(color: Colors.white60, fontSize: 10),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Row(
            children: [
              const Icon(Icons.toll_rounded, color: Colors.amber, size: 12),
              const SizedBox(width: 2),
              Text(
                _formatCoins(sender.totalCoins),
                style: const TextStyle(
                  color: Colors.amber,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatCoins(int coins) {
    if (coins >= 1000) return '${(coins / 1000).toStringAsFixed(1)}K';
    return coins.toString();
  }
}
