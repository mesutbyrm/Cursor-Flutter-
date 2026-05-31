import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../../domain/pk/pk_battle_state.dart';
import '../../../theme/voice_room_tokens.dart';
import 'pk_vs_emblem.dart';

/// TikTok PK — çift renkli animasyonlu skor çubuğu + timer + win streak.
class PkAnimatedScoreBar extends StatelessWidget {
  const PkAnimatedScoreBar({
    super.key,
    required this.state,
    this.compact = false,
  });

  final PkBattleState state;
  final bool compact;

  static String fmt(int n) {
    if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}K';
    return '$n';
  }

  @override
  Widget build(BuildContext context) {
    final ratio = state.leftRatio;
    final h = compact ? 52.0 : 64.0;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          height: h,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final w = constraints.maxWidth;
              final split = w * ratio;

              return Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.center,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: Row(
                      children: [
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 520),
                          curve: Curves.easeOutCubic,
                          width: split,
                          height: h,
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Color(0xFF00D2FF),
                                Color(0xFF1565C0),
                              ],
                            ),
                          ),
                          alignment: Alignment.centerLeft,
                          padding: const EdgeInsets.only(left: 12),
                          child: _ScoreLabel(
                            value: state.left.total,
                            align: TextAlign.left,
                          ),
                        ),
                        Expanded(
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 520),
                            curve: Curves.easeOutCubic,
                            height: h,
                            decoration: const BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Color(0xFFFF2D7A),
                                  Color(0xFFB832FF),
                                ],
                              ),
                            ),
                            alignment: Alignment.centerRight,
                            padding: const EdgeInsets.only(right: 12),
                            child: _ScoreLabel(
                              value: state.right.total,
                              align: TextAlign.right,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Positioned(
                    top: -6,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.75),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: VoiceRoomTokens.gold.withValues(alpha: 0.7),
                        ),
                        boxShadow: VoiceRoomTokens.goldGlow(blur: 10),
                      ),
                      child: Text(
                        state.timerLabel,
                        style: const TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 15,
                          color: VoiceRoomTokens.gold,
                          letterSpacing: 1.4,
                          fontFeatures: [FontFeature.tabularFigures()],
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
        if (!compact) ...[
          const SizedBox(height: 8),
          Row(
            children: [
              _StreakChip(label: '${state.left.winStreak}x WIN', color: VoiceRoomTokens.neonPink),
              const Spacer(),
              const PkVsEmblem(size: 56, pulse: true),
              const Spacer(),
              _StreakChip(label: '${state.right.winStreak}x WIN', color: VoiceRoomTokens.neonBlue),
            ],
          ),
        ],
      ],
    ).animate().fadeIn(duration: 400.ms).slideY(begin: -0.08, end: 0);
  }
}

class _ScoreLabel extends StatelessWidget {
  const _ScoreLabel({required this.value, required this.align});

  final int value;
  final TextAlign align;

  @override
  Widget build(BuildContext context) {
    return Text(
      PkAnimatedScoreBar.fmt(value),
      textAlign: align,
      style: const TextStyle(
        fontWeight: FontWeight.w900,
        fontSize: 15,
        color: Colors.white,
        shadows: [Shadow(color: Colors.black54, blurRadius: 4)],
      ),
    );
  }
}

class _StreakChip extends StatelessWidget {
  const _StreakChip({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w900,
          color: color,
        ),
      ),
    );
  }
}
