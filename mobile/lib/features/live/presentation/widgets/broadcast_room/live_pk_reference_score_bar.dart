import 'package:flutter/material.dart';

import '../../../../voice_hub/presentation/widgets/premium_2026/pk/pk_animated_score_bar.dart';
import '../../../domain/pk/live_pk_status_pill_mode.dart';
import 'pk_status_pill.dart';

/// Referans — skorlar üstte, bar ortada, yüzde satırı, altında durum pill.
class LivePkReferenceScoreBar extends StatelessWidget {
  const LivePkReferenceScoreBar({
    super.key,
    required this.leftScore,
    required this.rightScore,
    this.pillMode = PkStatusPillMode.active,
    this.winnerName,
    this.active = true,
    this.showEndedScores = false,
  });

  final int leftScore;
  final int rightScore;
  final PkStatusPillMode pillMode;
  final String? winnerName;
  final bool active;
  final bool showEndedScores;

  static double leftRatio(int left, int right) {
    final t = left + right;
    if (t <= 0) return 0.5;
    return (left / t).clamp(0.0, 1.0);
  }

  @override
  Widget build(BuildContext context) {
    final ratio = leftRatio(leftScore, rightScore);
    final leftPct = (ratio * 100).round();
    final rightPct = 100 - leftPct;
    final highlight = !active || showEndedScores;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(
                child: _ScoreNumber(
                  value: leftScore,
                  alignStart: true,
                  colors: const [Color(0xFFFF2D7A), Color(0xFFB832FF)],
                ),
              ),
              Expanded(
                child: _ScoreNumber(
                  value: rightScore,
                  alignStart: false,
                  colors: const [Color(0xFF00D2FF), Color(0xFF448AFF)],
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: SizedBox(
              height: 12,
              child: Row(
                children: [
                  Expanded(
                    flex: (ratio * 1000).round().clamp(1, 999),
                    child: const DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Color(0xFFFF2D7A), Color(0xFFB832FF)],
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    flex: ((1 - ratio) * 1000).round().clamp(1, 999),
                    child: const DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Color(0xFF00D2FF), Color(0xFF448AFF)],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Text(
                '$leftPct%',
                style: const TextStyle(
                  color: Color(0xFFFF6B9D),
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const Spacer(),
              Text(
                '$rightPct%',
                style: const TextStyle(
                  color: Color(0xFF64B5F6),
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Center(
            child: PkStatusPill(
              mode: pillMode,
              winnerName: winnerName,
              highlight: highlight,
            ),
          ),
        ],
      ),
    );
  }
}

class _ScoreNumber extends StatelessWidget {
  const _ScoreNumber({
    required this.value,
    required this.alignStart,
    required this.colors,
  });

  final int value;
  final bool alignStart;
  final List<Color> colors;

  @override
  Widget build(BuildContext context) {
    return Text(
      PkAnimatedScoreBar.fmt(value),
      textAlign: alignStart ? TextAlign.left : TextAlign.right,
      style: TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.w900,
        foreground: Paint()
          ..shader = LinearGradient(colors: colors)
              .createShader(const Rect.fromLTWH(0, 0, 140, 30)),
      ),
    );
  }
}

