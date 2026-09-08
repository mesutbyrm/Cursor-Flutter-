import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../domain/site_animation_command.dart';
import '../../domain/site_animation_tier.dart';
import '../utils/site_animation_seat_anchor.dart';

/// Koltukta oturan kullanıcı için tier bazlı glow efekti.
class SiteAnimationSeatRankGlow extends StatefulWidget {
  const SiteAnimationSeatRankGlow({
    super.key,
    required this.command,
  });

  final SiteAnimationCommand command;

  @override
  State<SiteAnimationSeatRankGlow> createState() =>
      _SiteAnimationSeatRankGlowState();
}

class _SiteAnimationSeatRankGlowState extends State<SiteAnimationSeatRankGlow>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final seat = widget.command.layout.seatIndex;
    if (seat == null || seat < 0) return const SizedBox.shrink();

    final rect = SiteAnimationSeatAnchor.seatRect(context: context, seatIndex: seat);
    final color = _color(widget.command.tier);
    final isHost = widget.command.tier == SiteAnimationTier.host;

    return AnimatedBuilder(
      animation: _pulse,
      builder: (context, child) {
        final glow = 0.35 + _pulse.value * 0.35;
        final scale = isHost ? 1.12 + _pulse.value * 0.08 : 1 + _pulse.value * 0.06;
        return Positioned(
          left: rect.left - 6,
          top: rect.top - 6,
          width: rect.width + 12,
          height: rect.height + 12,
          child: Transform.scale(
            scale: scale,
            child: DecoratedBox(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: color.withValues(alpha: 0.65 + _pulse.value * 0.2),
                  width: isHost ? 2.5 : 1.8,
                ),
                boxShadow: [
                  BoxShadow(
                    color: color.withValues(alpha: glow),
                    blurRadius: isHost ? 18 : 12,
                  ),
                ],
              ),
              child: isHost
                  ? CustomPaint(
                      painter: _HostRingPainter(
                        phase: _pulse.value,
                        color: color,
                      ),
                    )
                  : null,
            ),
          ),
        );
      },
    );
  }

  Color _color(SiteAnimationTier tier) => switch (tier) {
        SiteAnimationTier.admin => const Color(0xFFFF5252),
        SiteAnimationTier.host => const Color(0xFFFFD54F),
        SiteAnimationTier.diamond => const Color(0xFF7DF9FF),
        SiteAnimationTier.svip => const Color(0xFFFF6EC7),
        SiteAnimationTier.premium => const Color(0xFFB388FF),
        SiteAnimationTier.gold => const Color(0xFFFFD54F),
        SiteAnimationTier.vip => const Color(0xFF69F0AE),
        SiteAnimationTier.normal => Colors.white54,
      };
}

class _HostRingPainter extends CustomPainter {
  _HostRingPainter({required this.phase, required this.color});

  final double phase;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..color = color.withValues(alpha: 0.5 + phase * 0.3);
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.shortestSide / 2 - 4;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      phase * math.pi * 2,
      math.pi * 1.2,
      false,
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant _HostRingPainter oldDelegate) =>
      oldDelegate.phase != phase;
}
