import 'package:flutter/material.dart';

import '../../domain/entities/dream_contest_entity.dart';

class DreamContestCard extends StatelessWidget {
  final DreamContest contest;

  const DreamContestCard({
    Key? key,
    required this.contest,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (contest.imageUrl != null)
            ClipRRect(
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(12)),
              child: Image.network(
                contest.imageUrl!,
                height: 150,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  height: 150,
                  color: Colors.grey[300],
                  child: const Icon(Icons.image_not_supported),
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  contest.title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  contest.description,
                  style: const TextStyle(fontSize: 13, color: Colors.grey),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _StatItem(
                      label: 'Katılımcı',
                      value: '${contest.currentEntries}/${contest.maxEntries}',
                    ),
                    _StatItem(
                      label: 'Toplam Oy',
                      value: '${contest.totalVotes}',
                    ),
                    _StatItem(
                      label: 'Ödül',
                      value: '${contest.prizePool}',
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: contest.isFull ? 1.0 : contest.currentEntries / contest.maxEntries,
                    minHeight: 6,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      contest.isEnded ? Colors.grey : Colors.blue,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  contest.isEnded
                      ? 'Yarışma sona erdi'
                      : 'Kalan gün: ${contest.daysRemaining}',
                  style: TextStyle(
                    fontSize: 12,
                    color: contest.isEnded ? Colors.red : Colors.green,
                    fontWeight: FontWeight.bold,
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

class _StatItem extends StatelessWidget {
  final String label;
  final String value;

  const _StatItem({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.blue,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(fontSize: 11, color: Colors.grey),
        ),
      ],
    );
  }
}
