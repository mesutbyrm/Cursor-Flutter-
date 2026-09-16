import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../../voice_hub/presentation/widgets/premium_2026/pk/pk_animated_score_bar.dart';
import '../../../../voice_hub/presentation/theme/voice_room_tokens.dart';

/// Skor + progress — videoların üstünde gradient alt bölümde (Bigo/TikTok mantığı).
class LivePkImmersiveScoreOverlay extends StatelessWidget {
  const LivePkImmersiveScoreOverlay({
    super.key,
    required this.leftScore,
    required this.rightScore,
    required this.leftLabel,
    required this.rightLabel,
    this.showTieHint = false,
  });

  final int leftScore;
  final int rightScore;
  final String leftLabel;
  final String rightLabel;
  final bool showTieHint;

  double _ratio() {
    final t = leftScore + rightScore;
    if (t <= 0) return 0.5;
    return (leftScore / t).clamp(0.08, 0.92);
  }

  @override
  Widget build(BuildContext context) {
    final ratio = _ratio();
    final tied = leftScore == rightScore;

    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          colors: [
            Colors.black.withValues(alpha: 0.82),
            Colors.black.withValues(alpha: 0.35),
            Colors.transparent,
          ],
          stops: const [0, 0.55, 1],
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 28, 16, 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (showTieHint && tied)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.handshake_rounded,
                        color: VoiceRoomTokens.gold, size: 20),
                    const SizedBox(width: 6),
                    Text(
                      'Berabere ${PkAnimatedScoreBar.fmt(leftScore)} - ${PkAnimatedScoreBar.fmt(rightScore)}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            Row(
              children: [
                Expanded(
                  child: _ScoreCol(
                    label: leftLabel,
                    value: leftScore,
                    align: TextAlign.start,
                    accent: const Color(0xFF00D2FF),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Text(
                    'PK',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.5),
                      fontWeight: FontWeight.w900,
                      fontSize: 11,
                    ),
                  ),
                ),
                Expanded(
                  child: _ScoreCol(
                    label: rightLabel,
                    value: rightScore,
                    align: TextAlign.end,
                    accent: const Color(0xFFFF2D7A),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: SizedBox(
                height: 8,
                child: Row(
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 480),
                      curve: Curves.easeOutCubic,
                      width: MediaQuery.sizeOf(context).width * ratio * 0.88,
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Color(0xFF00D2FF), Color(0xFF1565C0)],
                        ),
                      ),
                    ),
                    Expanded(
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 480),
                        curve: Curves.easeOutCubic,
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Color(0xFFFF2D7A), Color(0xFFB832FF)],
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
      ),
    ).animate().fadeIn(duration: 280.ms);
  }
}

class _ScoreCol extends StatelessWidget {
  const _ScoreCol({
    required this.label,
    required this.value,
    required this.align,
    required this.accent,
  });

  final String label;
  final int value;
  final TextAlign align;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: align == TextAlign.end
          ? CrossAxisAlignment.end
          : CrossAxisAlignment.start,
      children: [
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: align,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.75),
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
        Text(
          PkAnimatedScoreBar.fmt(value),
          textAlign: align,
          style: TextStyle(
            color: accent,
            fontSize: 22,
            fontWeight: FontWeight.w900,
            height: 1.1,
            shadows: [
              Shadow(color: accent.withValues(alpha: 0.55), blurRadius: 12),
            ],
          ),
        ),
      ],
    );
  }
}
