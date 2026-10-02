import 'package:flutter/material.dart';

import '../../../../voice_hub/presentation/widgets/premium_2026/pk/pk_animated_score_bar.dart';
import '../../../domain/pk/live_pk_status_pill_mode.dart';
import 'pk_status_pill.dart';
import 'live_pk_resolved_timer.dart';

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
    this.endsAt,
    this.fallbackSeconds = 0,
    this.countdownActive = false,
    this.onCountdownExpired,
  });

  final int leftScore;
  final int rightScore;
  final PkStatusPillMode pillMode;
  final String? winnerName;
  final bool active;
  final bool showEndedScores;
  final DateTime? endsAt;
  final int fallbackSeconds;
  final bool countdownActive;
  final VoidCallback? onCountdownExpired;

  static double leftRatio(int left, int right) {
    final t = left + right;
    if (t <= 0) return 0.5;
    return (left / t).clamp(0.0, 1.0);
  }

  static const _leftColors = [Color(0xFFFF3B5C), Color(0xFFFF7A59)];
  static const _rightColors = [Color(0xFF2979FF), Color(0xFF4FC3F7)];

  @override
  Widget build(BuildContext context) {
    final ratio = leftRatio(leftScore, rightScore);
    final highlight = !active || showEndedScores;

    return Semantics(
      container: true,
      label: 'PK skoru: $leftScore – $rightScore',
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Bigo/TikTok: tek şerit — kırmızı (sol) | mavi (sağ), sayılar
            // şeridin uçlarında, ayırıcı skorla birlikte kayar.
            TweenAnimationBuilder<double>(
              tween: Tween<double>(end: ratio),
              duration: const Duration(milliseconds: 260),
              curve: Curves.easeOutCubic,
              builder: (context, r, _) {
                final lf = (r * 1000).round().clamp(60, 940);
                return ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: SizedBox(
                    height: 28,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              flex: lf,
                              child: const DecoratedBox(
                                decoration: BoxDecoration(
                                  gradient:
                                      LinearGradient(colors: _leftColors),
                                ),
                              ),
                            ),
                            Expanded(
                              flex: 1000 - lf,
                              child: const DecoratedBox(
                                decoration: BoxDecoration(
                                  gradient:
                                      LinearGradient(colors: _rightColors),
                                ),
                              ),
                            ),
                          ],
                        ),
                        Positioned.fill(
                          child: Row(
                            children: [
                              Expanded(
                                flex: lf,
                                child: const Align(
                                  alignment: Alignment.centerRight,
                                  child: SizedBox(
                                    width: 3,
                                    child: DecoratedBox(
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.white70,
                                            blurRadius: 8,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              Expanded(flex: 1000 - lf, child: const SizedBox()),
                            ],
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          child: Row(
                            children: [
                              _ScoreNumber(value: leftScore, alignStart: true),
                              const Spacer(),
                              _ScoreNumber(
                                value: rightScore,
                                alignStart: false,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
            if (countdownActive && active && !showEndedScores) ...[
              const SizedBox(height: 6),
              LivePkResolvedTimer(
                fallbackSeconds: fallbackSeconds,
                endsAt: endsAt,
                countdownActive: true,
                centered: true,
                onExpired: onCountdownExpired,
              ),
            ],
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
      ),
    );
  }
}

class _ScoreNumber extends StatelessWidget {
  const _ScoreNumber({required this.value, required this.alignStart});

  final int value;
  final bool alignStart;

  @override
  Widget build(BuildContext context) {
    return Text(
      PkAnimatedScoreBar.fmt(value),
      maxLines: 1,
      textAlign: alignStart ? TextAlign.left : TextAlign.right,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w900,
        color: Colors.white,
        shadows: [Shadow(color: Colors.black54, blurRadius: 4)],
      ),
    );
  }
}
