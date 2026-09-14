import 'package:flutter/material.dart';

import '../../data/pk_models.dart';

/// Aktif / duraklatılmış PK skor şeridi.
class PkScoreBar extends StatelessWidget {
  const PkScoreBar({
    super.key,
    required this.battle,
    this.leftLabel = 'Sen',
    this.rightLabel = 'Rakip',
    this.remaining,
  });

  final PkBattle battle;
  final String leftLabel;
  final String rightLabel;
  final Duration? remaining;

  @override
  Widget build(BuildContext context) {
    final total = (battle.score1 + battle.score2).clamp(1, 999999999);
    final leftFlex = (battle.score1 / total * 100).round().clamp(10, 90);
    final paused = battle.status == PkStatus.paused;
    final rem = remaining?.inSeconds;

    return Opacity(
      opacity: paused ? 0.55 : 1,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.55),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          children: [
            Row(
              children: [
                Text(
                  leftLabel,
                  style: const TextStyle(color: Colors.white70, fontSize: 11),
                ),
                const Spacer(),
                if (paused)
                  const Padding(
                    padding: EdgeInsets.only(right: 8),
                    child: Text(
                      'Duraklatıldı',
                      style: TextStyle(
                        color: Colors.orangeAccent,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                if (rem != null && rem > 0)
                  Text(
                    '${rem ~/ 60}:${(rem % 60).toString().padLeft(2, '0')}',
                    style: const TextStyle(
                      color: Color(0xFFFFD700),
                      fontWeight: FontWeight.w800,
                      fontSize: 12,
                    ),
                  ),
                const Spacer(),
                Text(
                  rightLabel,
                  style: const TextStyle(color: Colors.white70, fontSize: 11),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                Text(
                  '${battle.score1}',
                  style: const TextStyle(
                    color: Color(0xFFFF6B9D),
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const Spacer(),
                Text(
                  '${battle.score2}',
                  style: const TextStyle(
                    color: Color(0xFF4DD0E1),
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: SizedBox(
                height: 6,
                child: Row(
                  children: [
                    Expanded(
                      flex: leftFlex,
                      child: const ColoredBox(color: Color(0xFFFF6B9D)),
                    ),
                    Expanded(
                      flex: 100 - leftFlex,
                      child: const ColoredBox(color: Color(0xFF4DD0E1)),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
