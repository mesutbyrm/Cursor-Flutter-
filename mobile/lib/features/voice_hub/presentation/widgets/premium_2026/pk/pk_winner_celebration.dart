import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../../domain/pk/pk_battle_mode.dart';
import '../../../../domain/pk/pk_battle_state.dart';
import '../../../theme/voice_room_tokens.dart';
import 'pk_animated_score_bar.dart';

/// Kazanan animasyonu — konfeti, taç, neon burst.
class PkWinnerCelebration extends StatelessWidget {
  const PkWinnerCelebration({
    super.key,
    required this.state,
    required this.onRestart,
    required this.onClose,
  });

  final PkBattleState state;
  final VoidCallback onRestart;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    if (!state.isFinished) return const SizedBox.shrink();

    final winner = state.winner;
    final title = switch (winner) {
      PkBattleWinner.left => state.mode == PkBattleMode.team
          ? 'TAKIM A KAZANDI!'
          : '${state.left.leader?.displayName ?? "Sol"} KAZANDI!',
      PkBattleWinner.right => state.mode == PkBattleMode.team
          ? 'TAKIM B KAZANDI!'
          : '${state.right.leader?.displayName ?? "Sağ"} KAZANDI!',
      PkBattleWinner.tie => 'BERABERE!',
      PkBattleWinner.none => '',
    };

    final accent = switch (winner) {
      PkBattleWinner.left => VoiceRoomTokens.neonPink,
      PkBattleWinner.right => VoiceRoomTokens.neonBlue,
      _ => VoiceRoomTokens.gold,
    };

    return IgnorePointer(
      ignoring: false,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Container(color: Colors.black.withValues(alpha: 0.72)),
          CustomPaint(
            painter: _ConfettiPainter(seed: state.reactionBurst),
            size: Size.infinite,
          ),
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  winner == PkBattleWinner.tie
                      ? Icons.handshake_rounded
                      : Icons.emoji_events_rounded,
                  size: 72,
                  color: VoiceRoomTokens.gold,
                  shadows: [
                    Shadow(
                      color: accent.withValues(alpha: 0.9),
                      blurRadius: 24,
                    ),
                  ],
                )
                    .animate()
                    .scale(
                      begin: const Offset(0.2, 0.2),
                      end: const Offset(1, 1),
                      duration: 600.ms,
                      curve: Curves.elasticOut,
                    ),
                const SizedBox(height: 16),
                ShaderMask(
                  shaderCallback: (b) => LinearGradient(
                    colors: [accent, VoiceRoomTokens.gold, Colors.white],
                  ).createShader(b),
                  child: Text(
                    title,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '${PkAnimatedScoreBar.fmt(state.left.total)} — ${PkAnimatedScoreBar.fmt(state.right.total)}',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.75),
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 28),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    OutlinedButton(
                      onPressed: onClose,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white70,
                        side: const BorderSide(color: Colors.white24),
                      ),
                      child: const Text('Kapat'),
                    ),
                    const SizedBox(width: 12),
                    FilledButton(
                      onPressed: onRestart,
                      style: FilledButton.styleFrom(
                        backgroundColor: accent,
                      ),
                      child: const Text('Tekrar PK'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 280.ms);
  }
}

class _ConfettiPainter extends CustomPainter {
  _ConfettiPainter({required this.seed});

  final int seed;

  @override
  void paint(Canvas canvas, Size size) {
    final rand = math.Random(seed);
    for (var i = 0; i < 80; i++) {
      final x = rand.nextDouble() * size.width;
      final y = rand.nextDouble() * size.height;
      final paint = Paint()
        ..color = [
          VoiceRoomTokens.neonPink,
          VoiceRoomTokens.neonBlue,
          VoiceRoomTokens.gold,
          Colors.white,
        ][i % 4]
            .withValues(alpha: 0.35 + rand.nextDouble() * 0.5);
      canvas.drawCircle(Offset(x, y), 2 + rand.nextDouble() * 3, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _ConfettiPainter old) => old.seed != seed;
}
