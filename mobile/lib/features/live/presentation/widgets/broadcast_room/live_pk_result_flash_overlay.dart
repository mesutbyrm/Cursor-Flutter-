import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

/// PK bittiğinde ~2.5 sn kazanan / kaybeden / berabere flaşı (split video altında kalır).
class LivePkResultFlashOverlay extends StatelessWidget {
  const LivePkResultFlashOverlay({
    super.key,
    required this.visible,
    required this.isDraw,
    required this.iWon,
    this.myScore = 0,
    this.opponentScore = 0,
  });

  final bool visible;
  final bool isDraw;
  final bool iWon;
  final int myScore;
  final int opponentScore;

  @override
  Widget build(BuildContext context) {
    if (!visible) return const SizedBox.shrink();

    final (title, emoji, accent) = isDraw
        ? ('BERABERE', '⚔', const Color(0xFF7DD3FC))
        : iWon
            ? ('KAZANDIN!', '👑', const Color(0xFFFFD54F))
            : ('PK BİTTİ', '—', Colors.white70);
    final isLoss = !isDraw && !iWon;

    return IgnorePointer(
      child: Container(
        color: Colors.black.withValues(alpha: isLoss ? 0.5 : 0.55),
        alignment: Alignment.center,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (emoji != '—')
              Text(emoji, style: const TextStyle(fontSize: 48)),
            const SizedBox(height: 8),
            Text(
              isLoss ? 'Kaybettin' : title,
              style: TextStyle(
                color: accent,
                fontSize: isLoss ? 22 : 28,
                fontWeight: FontWeight.w900,
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _scoreBox(myScore, highlight: iWon && !isDraw),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    isDraw ? '=' : 'VS',
                    style: const TextStyle(
                      color: Colors.white54,
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                    ),
                  ),
                ),
                _scoreBox(
                  opponentScore,
                  highlight: isLoss,
                ),
              ],
            ),
          ],
        )
            .animate()
            .fadeIn(duration: 220.ms)
            .scale(
              begin: const Offset(0.92, 0.92),
              end: const Offset(1, 1),
              duration: 320.ms,
              curve: Curves.easeOutBack,
            ),
      ),
    );
  }

  Widget _scoreBox(int score, {required bool highlight}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: highlight
            ? const Color(0xFFFFD54F).withValues(alpha: 0.2)
            : Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: highlight
              ? const Color(0xFFFFD54F)
              : Colors.white24,
        ),
      ),
      child: Text(
        _fmt(score),
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w900,
          fontSize: 18,
        ),
      ),
    );
  }

  String _fmt(int n) {
    if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}K';
    return '$n';
  }
}
