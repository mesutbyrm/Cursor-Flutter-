import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../theme/voice_room_tokens.dart';

/// TikTok tarzı büyük VS — glitch + neon glow.
class PkVsEmblem extends StatefulWidget {
  const PkVsEmblem({
    super.key,
    this.size = 88,
    this.pulse = true,
  });

  final double size;
  final bool pulse;

  @override
  State<PkVsEmblem> createState() => _PkVsEmblemState();
}

class _PkVsEmblemState extends State<PkVsEmblem>
    with SingleTickerProviderStateMixin {
  late AnimationController _glitch;

  @override
  void initState() {
    super.initState();
    _glitch = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat();
  }

  @override
  void dispose() {
    _glitch.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.size;
    Widget core = AnimatedBuilder(
      animation: _glitch,
      builder: (context, _) {
        final t = _glitch.value;
        final dx = math.sin(t * math.pi * 8) * 2.5;
        return Stack(
          alignment: Alignment.center,
          children: [
            CustomPaint(
              size: Size(s * 1.35, s * 1.35),
              painter: _HudRingPainter(phase: t),
            ),
            Transform.translate(
              offset: Offset(-dx, 0),
              child: Text(
                'VS',
                style: TextStyle(
                  fontSize: s * 0.32,
                  fontWeight: FontWeight.w900,
                  color: VoiceRoomTokens.neonPink.withValues(alpha: 0.55),
                  letterSpacing: 2,
                ),
              ),
            ),
            Transform.translate(
              offset: Offset(dx, 0),
              child: Text(
                'VS',
                style: TextStyle(
                  fontSize: s * 0.32,
                  fontWeight: FontWeight.w900,
                  color: VoiceRoomTokens.neonBlue.withValues(alpha: 0.55),
                  letterSpacing: 2,
                ),
              ),
            ),
            Text(
              'VS',
              style: TextStyle(
                fontSize: s * 0.32,
                fontWeight: FontWeight.w900,
                color: Colors.white,
                letterSpacing: 2,
                shadows: [
                  Shadow(
                    color: VoiceRoomTokens.neonPink.withValues(alpha: 0.9),
                    blurRadius: 16,
                  ),
                  Shadow(
                    color: VoiceRoomTokens.neonBlue.withValues(alpha: 0.7),
                    blurRadius: 12,
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );

    core = Container(
      width: s,
      height: s,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const LinearGradient(
          colors: [Color(0xFF1A1035), Color(0xFF0A0618)],
        ),
        border: Border.all(color: Colors.white.withValues(alpha: 0.85), width: 2.5),
        boxShadow: [
          ...VoiceRoomTokens.neonGlow(VoiceRoomTokens.neonPink, blur: 28),
          ...VoiceRoomTokens.goldGlow(blur: 12),
        ],
      ),
      alignment: Alignment.center,
      child: core,
    );

    if (widget.pulse) {
      core = core
          .animate(onPlay: (c) => c.repeat(reverse: true))
          .scale(
            begin: const Offset(0.94, 0.94),
            end: const Offset(1.06, 1.06),
            duration: 900.ms,
          );
    }
    return core;
  }
}

class _HudRingPainter extends CustomPainter {
  _HudRingPainter({required this.phase});

  final double phase;

  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2);
    final r = size.width * 0.42;
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..color = VoiceRoomTokens.neonBlue.withValues(alpha: 0.65);
    canvas.drawArc(
      Rect.fromCircle(center: c, radius: r),
      phase * math.pi * 2,
      math.pi * 0.9,
      false,
      paint,
    );
    paint.color = VoiceRoomTokens.neonPink.withValues(alpha: 0.5);
    canvas.drawArc(
      Rect.fromCircle(center: c, radius: r * 0.88),
      -phase * math.pi * 2,
      math.pi * 0.7,
      false,
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant _HudRingPainter old) => old.phase != phase;
}
