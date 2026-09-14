import 'package:flutter/material.dart';

/// Canlı yayın overlay chip'leri — `live_broadcast_room_page` parçası.
class LiveBroadcastLastJoinedChip extends StatelessWidget {
  const LiveBroadcastLastJoinedChip({super.key, required this.name});

  final String name;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF7C4DFF).withValues(alpha: 0.55)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.waving_hand_rounded,
                size: 14, color: Color(0xFFFFD54F)),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                '$name yayına katıldı',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class LiveBroadcastLikeContributorsChip extends StatelessWidget {
  const LiveBroadcastLikeContributorsChip({super.key, required this.counts});

  final Map<String, int> counts;

  @override
  Widget build(BuildContext context) {
    final top = counts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final line = top.take(3).map((e) => '❤️ ${e.value}').join('  ');
    if (line.isEmpty) return const SizedBox.shrink();
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white24),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Text(
          line,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 11,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}
