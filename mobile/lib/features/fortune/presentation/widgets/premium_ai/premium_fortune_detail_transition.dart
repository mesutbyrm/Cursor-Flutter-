import 'dart:async';
import 'dart:math' as math;

import 'package:canlifal_social/core/performance/effects_perf.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../domain/entities/fortune_type_entity.dart';
import '../../data/fortune_type_images.dart';
import '../../services/fortune_ambient_audio.dart';
import '../premium_2026/cinematic_fortune_hero.dart';

/// Falını Aç — kısa kamera zoom, kozmik patlama.
Future<void> runPremiumFortuneOpenTransition({
  required BuildContext context,
  required FortuneTypeEntity type,
  required Future<void> Function() onOpen,
}) async {
  HapticFeedback.mediumImpact();
  unawaited(FortuneAmbientAudio.playOpening());
  final overlay = Overlay.of(context);
  late OverlayEntry entry;
  var dismissed = false;

  entry = OverlayEntry(
    builder: (ctx) => _OpenTransitionOverlay(
      type: type,
      onDone: () async {
        if (dismissed) return;
        dismissed = true;
        entry.remove();
        await onOpen();
      },
    ),
  );

  overlay.insert(entry);
}

class _OpenTransitionOverlay extends StatefulWidget {
  const _OpenTransitionOverlay({
    required this.type,
    required this.onDone,
  });

  final FortuneTypeEntity type;
  final VoidCallback onDone;

  @override
  State<_OpenTransitionOverlay> createState() => _OpenTransitionOverlayState();
}

class _OpenTransitionOverlayState extends State<_OpenTransitionOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..forward().then((_) {
        if (mounted) widget.onDone();
      });
    HapticFeedback.heavyImpact();
    Future<void>.delayed(const Duration(milliseconds: 800), () {
      if (mounted) HapticFeedback.lightImpact();
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final heroTag = 'fortune-open-${widget.type.slug}';
    final glow = FortuneTypeImages.glowColor(widget.type.slug);

    return Material(
      color: Colors.transparent,
      child: AnimatedBuilder(
        animation: _ctrl,
        builder: (_, _) {
          final t = Curves.easeInOutCubic.transform(_ctrl.value);
          final zoomT = Curves.easeOutCubic.transform(
            (_ctrl.value / 0.7).clamp(0.0, 1.0),
          );
          final blurOpacity = zoomT;
          final scale = 1.0 + 0.28 * zoomT;
          final spin = math.sin(t * math.pi) * 0.06;
          final burst = (_ctrl.value > 0.35 && _ctrl.value < 0.75)
              ? ((_ctrl.value - 0.35) / 0.4).clamp(0.0, 1.0)
              : 0.0;

          return Stack(
            fit: StackFit.expand,
            children: [
              EffectsPerf.backdrop(
                sigma: 12,
                child: Container(
                  color: Colors.black.withValues(alpha: 0.55 * blurOpacity),
                ),
              ),
              if (burst > 0)
                CustomPaint(
                  painter: _CosmicBurstPainter(
                    progress: burst,
                    color: glow,
                  ),
                ),
              Center(
                child: Transform.scale(
                  scale: scale,
                  child: Transform.rotate(
                    angle: spin,
                    child: SizedBox(
                      width: size.width * 0.92,
                      child: Hero(
                        tag: heroTag,
                        child: Material(
                          type: MaterialType.transparency,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              CinematicFortuneHero(
                                type: widget.type,
                                height: size.height * 0.44,
                                showTitle: false,
                              ),
                              if (burst > 0.2)
                                Container(
                                  width: size.width * 0.5,
                                  height: size.width * 0.5,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: glow.withValues(alpha: 0.5 * burst),
                                        blurRadius: 48 * burst,
                                        spreadRadius: 12 * burst,
                                      ),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              if (t > 0.15)
                Positioned(
                  bottom: size.height * 0.12,
                  left: 0,
                  right: 0,
                  child: Opacity(
                    opacity: ((t - 0.15) / 0.35).clamp(0.0, 1.0),
                    child: Text(
                      'Kozmik enerji açılıyor…',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.85),
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                        letterSpacing: 0.6,
                      ),
                    ),
                  ).animate(onPlay: (c) => c.repeat(reverse: true)).shimmer(
                        duration: 1200.ms,
                        color: glow.withValues(alpha: 0.4),
                      ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _CosmicBurstPainter extends CustomPainter {
  _CosmicBurstPainter({required this.progress, required this.color});

  final double progress;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.shortestSide * 0.45 * progress;
    final paint = Paint()
      ..shader = RadialGradient(
        colors: [
          color.withValues(alpha: 0.45 * (1 - progress)),
          Colors.transparent,
        ],
      ).createShader(Rect.fromCircle(center: center, radius: radius));
    canvas.drawCircle(center, radius, paint);

    final rayPaint = Paint()
      ..color = color.withValues(alpha: 0.2 * (1 - progress))
      ..strokeWidth = 2;
    for (var i = 0; i < 8; i++) {
      final angle = i * math.pi / 4;
      final end = center + Offset(
        math.cos(angle) * radius * 1.2,
        math.sin(angle) * radius * 1.2,
      );
      canvas.drawLine(center, end, rayPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _CosmicBurstPainter old) =>
      old.progress != progress;
}
