import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../domain/gift_rarity.dart';
import '../../../domain/premium_gift_catalog_2026.dart';
import '../../../../live/domain/entities/live_gift_event.dart';
import '../../../../live/presentation/gifts/widgets/floating_gift_particles.dart';
import '../gift_stage_layout.dart';

/// Hediye tam ekran animasyonu — hata sesli odayı çökertmesin.
class SafePremiumGiftFullscreenOverlay extends StatelessWidget {
  const SafePremiumGiftFullscreenOverlay({
    super.key,
    this.event,
    this.onDismissed,
    this.stageContext = GiftStageContext.voiceRoom,
    this.lightweight = false,
  });

  final LiveGiftEvent? event;
  final VoidCallback? onDismissed;
  final GiftStageContext stageContext;
  final bool lightweight;

  @override
  Widget build(BuildContext context) {
    if (event == null) return const SizedBox.shrink();
    return RepaintBoundary(
      child: PremiumGiftFullscreenOverlay(
        key: ValueKey('gift-fs-${event!.id}'),
        event: event,
        onDismissed: onDismissed,
        stageContext: stageContext,
        lightweight: lightweight,
      ),
    );
  }
}

/// Koltuk altı ↔ mesaj alanı — büyük hediye, yalnızca gönderen → alıcı etiketi.
class PremiumGiftFullscreenOverlay extends StatefulWidget {
  const PremiumGiftFullscreenOverlay({
    super.key,
    this.event,
    this.onDismissed,
    this.stageContext = GiftStageContext.voiceRoom,
    this.lightweight = false,
  });

  final LiveGiftEvent? event;
  final VoidCallback? onDismissed;
  final GiftStageContext stageContext;
  final bool lightweight;

  @override
  State<PremiumGiftFullscreenOverlay> createState() =>
      PremiumGiftFullscreenOverlayState();
}

class PremiumGiftFullscreenOverlayState extends State<PremiumGiftFullscreenOverlay>
    with TickerProviderStateMixin {
  final _particlesKey = GlobalKey<FloatingGiftParticlesState>();
  AnimationController? _glowCtrl;

  @override
  void initState() {
    super.initState();
    if (!widget.lightweight) {
      _glowCtrl = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 2400),
      )..repeat();
    }
    if (widget.event != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && widget.event != null) _triggerEffects(widget.event!);
      });
    }
  }

  @override
  void didUpdateWidget(covariant PremiumGiftFullscreenOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.event != null && widget.event!.id != oldWidget.event?.id) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && widget.event != null) _triggerEffects(widget.event!);
      });
    }
  }

  void _triggerEffects(LiveGiftEvent e) {
    if (widget.lightweight) return;
    final emoji = PremiumGiftCatalog2026.emoji(e.giftId);
    final comboBonus = (e.jetonAmount ~/ 50).clamp(0, 12);
    _particlesKey.currentState?.burst(emoji, count: 8 + comboBonus);
  }

  @override
  void dispose() {
    _glowCtrl?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final e = widget.event;
    if (e == null) return const SizedBox.shrink();

    final rarity = PremiumGiftCatalog2026.rarity(e.giftId);
    final glow = rarity.glowColor;

    return IgnorePointer(
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          GiftStageBand(
            stage: widget.stageContext,
            child: Stack(
              fit: StackFit.expand,
              children: [
                if (!widget.lightweight && _glowCtrl != null)
                  AnimatedBuilder(
                    animation: _glowCtrl!,
                    builder: (context, _) {
                      return CustomPaint(
                        painter: _StageGlowPainter(
                          phase: _glowCtrl!.value,
                          glow: glow,
                        ),
                        size: Size.infinite,
                      );
                    },
                  ),
                if (!widget.lightweight)
                  FloatingGiftParticles(
                    key: _particlesKey,
                    emojis: [PremiumGiftCatalog2026.emoji(e.giftId), '✨'],
                    spawnFromGiftId: e.giftId,
                  ),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final size = GiftStageMetrics.giftSizeFor(constraints);
                    return GiftStageLargeDisplay(
                      event: e,
                      giftSize: size,
                      showBackdrop: true,
                    );
                  },
                ),
              ],
            ),
          )
              .animate(key: ValueKey('gift-stage-${e.id}'))
              .fadeIn(duration: 220.ms)
              .scale(
                begin: const Offset(0.88, 0.88),
                end: const Offset(1, 1),
                curve: Curves.easeOutBack,
              ),
        ],
      ),
    );
  }
}

class _StageGlowPainter extends CustomPainter {
  _StageGlowPainter({required this.phase, required this.glow});

  final double phase;
  final Color glow;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    canvas.drawRect(
      rect,
      Paint()
        ..shader = RadialGradient(
          center: Alignment(
            -0.2 + sin(phase * pi * 2) * 0.15,
            0.1 + cos(phase * pi * 2) * 0.1,
          ),
          radius: 1.0,
          colors: [
            glow.withValues(alpha: 0.18),
            Colors.transparent,
          ],
        ).createShader(rect),
    );
  }

  @override
  bool shouldRepaint(covariant _StageGlowPainter old) =>
      old.phase != phase || old.glow != glow;
}
