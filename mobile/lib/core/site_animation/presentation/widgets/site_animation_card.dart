import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../domain/site_animation_command.dart';
import '../../domain/site_animation_layout.dart';
import '../../domain/site_animation_tier.dart';
import '../utils/site_animation_seat_anchor.dart';
import '../utils/site_animation_voice_room_layout.dart';
import 'site_animation_media.dart';

/// Premium giriş/çıkış kartı — slide + fade + scale; tam ekran kaplamaz.
class SiteAnimationCard extends StatefulWidget {
  const SiteAnimationCard({
    super.key,
    required this.command,
    required this.onFinished,
  });

  final SiteAnimationCommand command;
  final VoidCallback onFinished;

  @override
  State<SiteAnimationCard> createState() => _SiteAnimationCardState();
}

class _SiteAnimationCardState extends State<SiteAnimationCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;
  late final Animation<double> _scale;
  late final Animation<double> _pulse;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 520),
    );
    _fade = CurvedAnimation(
      parent: _ctrl,
      curve: const Interval(0, 0.35, curve: Curves.easeOut),
      reverseCurve: const Interval(0.65, 1, curve: Curves.easeIn),
    );
    _slide = Tween<Offset>(
      begin: const Offset(-0.42, 0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _ctrl,
      curve: const Interval(0, 0.35, curve: Curves.easeOutCubic),
      reverseCurve: const Interval(0.65, 1, curve: Curves.easeInCubic),
    ));
    _scale = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(begin: 0.9, end: 1.04)
            .chain(CurveTween(curve: Curves.easeOutBack)),
        weight: 35,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 1.04, end: 1.0)
            .chain(CurveTween(curve: Curves.easeInOut)),
        weight: 30,
      ),
      TweenSequenceItem(tween: ConstantTween(1.0), weight: 20),
      TweenSequenceItem(
        tween: Tween(begin: 1.0, end: 0.92)
            .chain(CurveTween(curve: Curves.easeIn)),
        weight: 15,
      ),
    ]).animate(_ctrl);
    _pulse = TweenSequence<double>([
      TweenSequenceItem(tween: ConstantTween(1.0), weight: 35),
      TweenSequenceItem(
        tween: Tween(begin: 1.0, end: 1.03)
            .chain(CurveTween(curve: Curves.easeInOut)),
        weight: 15,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 1.03, end: 1.0)
            .chain(CurveTween(curve: Curves.easeInOut)),
        weight: 15,
      ),
      TweenSequenceItem(tween: ConstantTween(1.0), weight: 20),
      TweenSequenceItem(tween: ConstantTween(1.0), weight: 15),
    ]).animate(_ctrl);

    _ctrl.forward();
    _scheduleExit();
  }

  void _scheduleExit() {
    final hold = widget.command.displayDuration -
        const Duration(milliseconds: 1040);
    Future<void>.delayed(hold, () async {
      if (!mounted) return;
      await _ctrl.reverse();
      if (mounted) widget.onFinished();
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    final width = (mq.size.width * 0.88).clamp(280.0, 360.0);
    final height = (width * 0.28).clamp(70.0, 110.0);
    final scale = widget.command.layout.scale;

    final scope = SiteAnimationVoiceRoomLayoutScope.maybeOf(context);
    final top = (scope?.stageTop ?? mq.padding.top) + 8;
    final left = widget.command.layout.anchor == SiteAnimationAnchor.topCenter
        ? (mq.size.width - width * scale) / 2
        : 12.0;
    final custom = widget.command.layout.position;

    return Positioned(
      left: custom?.dx ?? left,
      top: custom?.dy ?? top,
      width: width * scale,
      height: height * scale,
      child: FadeTransition(
        opacity: _fade,
        child: SlideTransition(
          position: _slide,
          child: ScaleTransition(
            scale: _scale,
            child: ScaleTransition(
              scale: _pulse,
              child: AnimatedBuilder(
                animation: _ctrl,
                builder: (context, child) => SiteAnimationMedia(
                  command: widget.command,
                  animationPhase: _ctrl.value,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Koltuk geçişi — oldSeat → newSeat glow animasyonu.
class SiteAnimationSeatTransition extends StatefulWidget {
  const SiteAnimationSeatTransition({
    super.key,
    required this.command,
  });

  final SiteAnimationCommand command;

  @override
  State<SiteAnimationSeatTransition> createState() =>
      _SiteAnimationSeatTransitionState();
}

class _SiteAnimationSeatTransitionState extends State<SiteAnimationSeatTransition>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final from = widget.command.layout.fromSeatIndex;
    final to = widget.command.layout.seatIndex;
    if (from == null || to == null) return const SizedBox.shrink();

    final color = _tierColor(widget.command.tier);

    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, child) {
        final t = Curves.easeInOutCubic.transform(_ctrl.value);
        final fromCenter = SiteAnimationSeatAnchor.seatCenter(context, from);
        final toCenter = SiteAnimationSeatAnchor.seatCenter(context, to);
        final pos = Offset.lerp(fromCenter, toCenter, t)!;
        final pulse = 1 + math.sin(t * math.pi) * 0.12;

        return Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned.fill(
              child: CustomPaint(
                painter: _SeatEnergyTrailPainter(
                  from: fromCenter,
                  to: toCenter,
                  progress: t,
                  color: color,
                ),
              ),
            ),
            Positioned(
              left: pos.dx - 28,
              top: pos.dy - 28,
              width: 56 * pulse,
              height: 56 * pulse,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      color.withValues(alpha: 0.75),
                      color.withValues(alpha: 0.15),
                      Colors.transparent,
                    ],
                    stops: const [0.2, 0.55, 1],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: color.withValues(alpha: 0.55),
                      blurRadius: 18,
                      spreadRadius: 2,
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Color _tierColor(SiteAnimationTier tier) => switch (tier) {
        SiteAnimationTier.admin => const Color(0xFFFF5252),
        SiteAnimationTier.host => const Color(0xFFFFD54F),
        SiteAnimationTier.diamond => const Color(0xFF7DF9FF),
        SiteAnimationTier.gold => const Color(0xFFFFD54F),
        SiteAnimationTier.premium => const Color(0xFFB388FF),
        _ => const Color(0xFF80CBC4),
      };
}

class _SeatEnergyTrailPainter extends CustomPainter {
  _SeatEnergyTrailPainter({
    required this.from,
    required this.to,
    required this.progress,
    required this.color,
  });

  final Offset from;
  final Offset to;
  final double progress;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    const trailCount = 7;
    for (var i = 0; i < trailCount; i++) {
      final lag = i / trailCount;
      final t = (progress - lag * 0.35).clamp(0.0, 1.0);
      if (t <= 0) continue;
      final eased = Curves.easeOut.transform(t);
      final point = Offset.lerp(from, to, eased)!;
      final radius = (10 - i * 0.9) * (0.6 + eased * 0.5);
      final paint = Paint()
        ..color = color.withValues(alpha: (0.45 - i * 0.05) * eased)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
      canvas.drawCircle(point, radius, paint);
    }

    final pathPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2
      ..shader = LinearGradient(
        colors: [
          color.withValues(alpha: 0.05),
          color.withValues(alpha: 0.35 * progress),
          color.withValues(alpha: 0.65 * progress),
        ],
        stops: const [0, 0.5, 1],
      ).createShader(Rect.fromPoints(from, to));
    canvas.drawLine(from, Offset.lerp(from, to, progress)!, pathPaint);
  }

  @override
  bool shouldRepaint(covariant _SeatEnergyTrailPainter oldDelegate) =>
      oldDelegate.progress != progress ||
      oldDelegate.from != from ||
      oldDelegate.to != to;
}
