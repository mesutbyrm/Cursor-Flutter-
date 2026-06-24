import 'dart:math';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

/// TikTok seviyesi PK overlay — geri sayım, MVP, kazanan efekti.
class LivePkPremiumOverlay extends StatefulWidget {
  const LivePkPremiumOverlay({
    super.key,
    required this.leftScore,
    required this.rightScore,
    required this.status,
    this.secondsLeft,
    this.topSupporter,
    this.mvpName,
    this.winnerSide,
  });

  final int leftScore;
  final int rightScore;
  final String status;
  final int? secondsLeft;
  final String? topSupporter;
  final String? mvpName;
  final String? winnerSide;

  @override
  State<LivePkPremiumOverlay> createState() => _LivePkPremiumOverlayState();
}

class _LivePkPremiumOverlayState extends State<LivePkPremiumOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _confetti;

  @override
  void initState() {
    super.initState();
    _confetti = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );
    if (widget.status == 'ended' && widget.winnerSide != null) {
      _confetti.forward();
    }
  }

  @override
  void didUpdateWidget(covariant LivePkPremiumOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.status == 'ended' &&
        widget.winnerSide != null &&
        oldWidget.status != 'ended') {
      _confetti.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _confetti.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final total = (widget.leftScore + widget.rightScore).clamp(1, 999999999);
    final leftPct = (widget.leftScore / total * 100).round();
    final rightPct = 100 - leftPct;

    return IgnorePointer(
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (widget.status == 'active')
            Center(
              child: Text(
                widget.secondsLeft != null ? '${widget.secondsLeft}s' : 'PK',
                style: TextStyle(
                  fontSize: 42,
                  fontWeight: FontWeight.w900,
                  color: Colors.white.withValues(alpha: 0.35),
                  shadows: const [Shadow(color: Color(0xFFB832FF), blurRadius: 24)],
                ),
              ).animate(onPlay: (c) => c.repeat()).shimmer(duration: 1200.ms),
            ),
          Positioned(
            top: MediaQuery.paddingOf(context).top + 120,
            left: 16,
            right: 16,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.42),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: Colors.white24),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          _team('Sen', widget.leftScore, leftPct, const Color(0xFFFF4D9D)),
                          const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 8),
                            child: Text('VS', style: TextStyle(color: Colors.white54)),
                          ),
                          _team('Rakip', widget.rightScore, rightPct, const Color(0xFF22D3EE)),
                        ],
                      ),
                      const SizedBox(height: 10),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: SizedBox(
                          height: 10,
                          child: Row(
                            children: [
                              Expanded(
                                flex: leftPct.clamp(5, 95),
                                child: Container(color: const Color(0xFFFF4D9D)),
                              ),
                              Expanded(
                                flex: rightPct.clamp(5, 95),
                                child: Container(color: const Color(0xFF22D3EE)),
                              ),
                            ],
                          ),
                        ),
                      ),
                      if (widget.topSupporter != null) ...[
                        const SizedBox(height: 8),
                        Text(
                          'En büyük destekçi: ${widget.topSupporter}',
                          style: const TextStyle(color: Colors.white70, fontSize: 11),
                        ),
                      ],
                      if (widget.mvpName != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          'MVP: ${widget.mvpName}',
                          style: const TextStyle(
                            color: Color(0xFFFFD700),
                            fontWeight: FontWeight.w900,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
          AnimatedBuilder(
            animation: _confetti,
            builder: (_, _) {
              if (_confetti.value <= 0) return const SizedBox.shrink();
              return CustomPaint(
                painter: _ConfettiPainter(_confetti.value),
                size: Size.infinite,
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _team(String label, int score, int pct, Color color) {
    return Expanded(
      child: Column(
        children: [
          Text(label, style: TextStyle(color: color, fontWeight: FontWeight.w800)),
          Text(
            '$score',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w900,
              fontSize: 22,
            ),
          ),
          Text('%$pct', style: const TextStyle(color: Colors.white54, fontSize: 10)),
        ],
      ),
    );
  }
}

class _ConfettiPainter extends CustomPainter {
  _ConfettiPainter(this.t);
  final double t;
  final _rng = Random(7);

  @override
  void paint(Canvas canvas, Size size) {
    for (var i = 0; i < 40; i++) {
      final x = _rng.nextDouble() * size.width;
      final y = (t * size.height * 1.2 + i * 18) % size.height;
      final paint = Paint()
        ..color = [
          const Color(0xFFFFD700),
          const Color(0xFFB832FF),
          const Color(0xFF22D3EE),
        ][_rng.nextInt(3)]
            .withValues(alpha: 0.85);
      canvas.drawRect(Rect.fromCenter(center: Offset(x, y), width: 6, height: 10), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _ConfettiPainter oldDelegate) => oldDelegate.t != t;
}
