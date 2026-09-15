import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Sol/sağ PK tarafı — skor ve bitiş durumuna göre çerçeve rengi.
enum PkSideOutcome { ahead, behind, tied, neutral }

PkSideOutcome pkSideOutcome({
  required bool isLeft,
  required int leftScore,
  required int rightScore,
  required bool battleActive,
  bool? leftWon,
  bool? rightWon,
  bool? isDraw,
}) {
  if (!battleActive && (leftWon == true || rightWon == true || isDraw == true)) {
    if (isDraw == true) return PkSideOutcome.tied;
    if (isLeft) {
      return leftWon == true ? PkSideOutcome.ahead : PkSideOutcome.behind;
    }
    return rightWon == true ? PkSideOutcome.ahead : PkSideOutcome.behind;
  }
  if (leftScore == rightScore) return PkSideOutcome.tied;
  final leftAhead = leftScore > rightScore;
  if (isLeft) {
    return leftAhead ? PkSideOutcome.ahead : PkSideOutcome.behind;
  }
  return leftAhead ? PkSideOutcome.behind : PkSideOutcome.ahead;
}

Color pkOutcomeColor(PkSideOutcome o) {
  switch (o) {
    case PkSideOutcome.ahead:
      return const Color(0xFF22C55E);
    case PkSideOutcome.behind:
      return const Color(0xFFEF4444);
    case PkSideOutcome.tied:
      return const Color(0xFF3B82F6);
    case PkSideOutcome.neutral:
      return Colors.white24;
  }
}

/// TikTok/Bigo tarzı yan panel — kazanan yeşil, kaybeden kırmızı, berabere mavi.
class PkOutcomeBorder extends StatefulWidget {
  const PkOutcomeBorder({
    super.key,
    required this.child,
    required this.outcome,
    this.borderRadius = 0,
    this.strokeWidth = 3,
    this.urgentPulse = false,
  });

  final Widget child;
  final PkSideOutcome outcome;
  final double borderRadius;
  final double strokeWidth;
  final bool urgentPulse;

  @override
  State<PkOutcomeBorder> createState() => _PkOutcomeBorderState();
}

class _PkOutcomeBorderState extends State<PkOutcomeBorder>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 520),
    );
    if (widget.urgentPulse) _pulse.repeat(reverse: true);
  }

  @override
  void didUpdateWidget(covariant PkOutcomeBorder oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.urgentPulse && !_pulse.isAnimating) {
      _pulse.repeat(reverse: true);
    } else if (!widget.urgentPulse && _pulse.isAnimating) {
      _pulse.stop();
      _pulse.value = 1;
    }
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final base = pkOutcomeColor(widget.outcome);
    return AnimatedBuilder(
      animation: _pulse,
      builder: (context, child) {
        final glow = widget.urgentPulse
            ? 0.45 + 0.55 * _pulse.value
            : (widget.outcome == PkSideOutcome.neutral ? 0.35 : 0.75);
        return DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(widget.borderRadius),
            border: Border.all(
              color: base.withValues(alpha: glow.clamp(0.2, 1.0)),
              width: widget.strokeWidth,
            ),
            boxShadow: [
              BoxShadow(
                color: base.withValues(alpha: 0.35 * glow),
                blurRadius: 12 + 8 * glow,
                spreadRadius: 1,
              ),
            ],
          ),
          child: child,
        );
      },
      child: widget.child,
    );
  }
}

/// Geri sayım — son saniyelerde yanıp söner.
class PkBattleTimerBadge extends StatefulWidget {
  const PkBattleTimerBadge({
    super.key,
    required this.secondsLeft,
    this.flashThreshold = 10,
  });

  final int secondsLeft;
  final int flashThreshold;

  @override
  State<PkBattleTimerBadge> createState() => _PkBattleTimerBadgeState();
}

class _PkBattleTimerBadgeState extends State<PkBattleTimerBadge>
    with SingleTickerProviderStateMixin {
  late final AnimationController _flash;

  @override
  void initState() {
    super.initState();
    _flash = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 380),
    );
  }

  @override
  void didUpdateWidget(covariant PkBattleTimerBadge oldWidget) {
    super.didUpdateWidget(oldWidget);
    final urgent = widget.secondsLeft > 0 &&
        widget.secondsLeft <= widget.flashThreshold;
    if (urgent && !_flash.isAnimating) {
      _flash.repeat(reverse: true);
    } else if (!urgent) {
      _flash.stop();
      _flash.value = 1;
    }
  }

  @override
  void dispose() {
    _flash.dispose();
    super.dispose();
  }

  String _label(int sec) {
    final m = sec ~/ 60;
    final s = sec % 60;
    if (m > 0) return '${m}:${s.toString().padLeft(2, '0')}';
    return '${sec}s';
  }

  @override
  Widget build(BuildContext context) {
    final sec = widget.secondsLeft.clamp(0, 99999);
    final urgent = sec > 0 && sec <= widget.flashThreshold;
    if (urgent && !_flash.isAnimating) {
      _flash.repeat(reverse: true);
    }
    final color = urgent ? const Color(0xFFFF3B30) : const Color(0xFFFFD700);

    return AnimatedBuilder(
      animation: _flash,
      builder: (context, _) {
        final scale = urgent ? 1.0 + 0.12 * _flash.value : 1.0;
        final opacity = urgent ? 0.55 + 0.45 * _flash.value : 1.0;
        return Transform.scale(
          scale: scale,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.72 * opacity),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: color.withValues(alpha: opacity),
                width: urgent ? 2 : 1,
              ),
              boxShadow: urgent
                  ? [
                      BoxShadow(
                        color: color.withValues(alpha: 0.5 * _flash.value),
                        blurRadius: 16,
                      ),
                    ]
                  : null,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.timer_outlined,
                  size: 16,
                  color: color.withValues(alpha: opacity),
                ),
                const SizedBox(width: 6),
                Text(
                  _label(sec),
                  style: TextStyle(
                    color: color.withValues(alpha: opacity),
                    fontWeight: FontWeight.w900,
                    fontSize: 15,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

int pkBattleSecondsLeftFromMap(Map<String, dynamic> battle) {
  final direct = battle['secondsLeft'] ?? battle['remainingSec'];
  if (direct != null) {
    final n = int.tryParse(direct.toString());
    if (n != null) return n;
  }
  final endsRaw = battle['endsAt']?.toString();
  if (endsRaw != null && endsRaw.isNotEmpty) {
    final ends = DateTime.tryParse(endsRaw);
    if (ends != null) {
      return math.max(0, ends.difference(DateTime.now()).inSeconds);
    }
  }
  return 0;
}

int pkScoreFromBattleMap(Map<String, dynamic> battle, {required bool left}) {
  if (left) {
    return int.tryParse(
          '${battle['score1'] ?? battle['leftScore'] ?? battle['challengerScore'] ?? 0}',
        ) ??
        0;
  }
  return int.tryParse(
        '${battle['score2'] ?? battle['rightScore'] ?? battle['opponentScore'] ?? 0}',
      ) ??
      0;
}
