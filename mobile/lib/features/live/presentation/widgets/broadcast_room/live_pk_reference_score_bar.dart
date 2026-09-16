import 'package:flutter/material.dart';

import '../../../../voice_hub/presentation/widgets/premium_2026/pk/pk_animated_score_bar.dart';

/// Referans görsel — iki taraflı skor, yüzde ve orta PK rozeti.
class LivePkReferenceScoreBar extends StatelessWidget {
  const LivePkReferenceScoreBar({
    super.key,
    required this.leftScore,
    required this.rightScore,
    required this.leftLabel,
    required this.rightLabel,
    this.statusLabel = 'PK devam ediyor!',
    this.active = true,
  });

  final int leftScore;
  final int rightScore;
  final String leftLabel;
  final String rightLabel;
  final String statusLabel;
  final bool active;

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

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(
                child: _SideScore(
                  label: leftLabel,
                  value: leftScore,
                  percent: leftPct,
                  alignStart: true,
                  gradient: const [Color(0xFFFF2D7A), Color(0xFFB832FF)],
                ),
              ),
              _CenterPill(label: active ? statusLabel : 'PK bitti'),
              Expanded(
                child: _SideScore(
                  label: rightLabel,
                  value: rightScore,
                  percent: rightPct,
                  alignStart: false,
                  gradient: const [Color(0xFF00D2FF), Color(0xFF448AFF)],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: SizedBox(
              height: 10,
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
        ],
      ),
    );
  }
}

class _CenterPill extends StatelessWidget {
  const _CenterPill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 6),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.65),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFB832FF).withValues(alpha: 0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.bolt_rounded, color: Color(0xFFFFD54F), size: 14),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _SideScore extends StatelessWidget {
  const _SideScore({
    required this.label,
    required this.value,
    required this.percent,
    required this.alignStart,
    required this.gradient,
  });

  final String label;
  final int value;
  final int percent;
  final bool alignStart;
  final List<Color> gradient;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment:
          alignStart ? CrossAxisAlignment.start : CrossAxisAlignment.end,
      children: [
        Text(
          PkAnimatedScoreBar.fmt(value),
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w900,
            foreground: Paint()
              ..shader = LinearGradient(colors: gradient)
                  .createShader(const Rect.fromLTWH(0, 0, 120, 28)),
          ),
        ),
        Text(
          '$percent%',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.75),
            fontSize: 11,
            fontWeight: FontWeight.w700,
          ),
        ),
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.55),
            fontSize: 10,
          ),
        ),
      ],
    );
  }
}
