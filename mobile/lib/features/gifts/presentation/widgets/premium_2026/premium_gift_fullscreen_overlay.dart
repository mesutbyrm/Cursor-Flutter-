import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../domain/premium_gift_catalog_2026.dart';
import '../../../../live/domain/entities/live_gift_event.dart';
import '../../../../live/presentation/gifts/widgets/floating_gift_particles.dart';
import '../gift_animation_player.dart';
import 'gift_coin_burst_overlay.dart';
import 'premium_gift_icon.dart';

/// TikTok Live — tam ekran hediye + combo + neon + parçacık + jeton.
class PremiumGiftFullscreenOverlay extends StatefulWidget {
  const PremiumGiftFullscreenOverlay({
    super.key,
    this.event,
    this.onDismissed,
  });

  final LiveGiftEvent? event;
  final VoidCallback? onDismissed;

  @override
  State<PremiumGiftFullscreenOverlay> createState() =>
      PremiumGiftFullscreenOverlayState();
}

class PremiumGiftFullscreenOverlayState extends State<PremiumGiftFullscreenOverlay>
    with SingleTickerProviderStateMixin {
  final _particlesKey = GlobalKey<FloatingGiftParticlesState>();
  final _coinKey = GlobalKey<GiftCoinBurstOverlayState>();
  late AnimationController _glowCtrl;

  @override
  void initState() {
    super.initState();
    _glowCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat();
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
    final emoji = PremiumGiftCatalog2026.emoji(e.giftId);
    _particlesKey.currentState?.burst(emoji, count: 10 + e.combo.clamp(0, 20));
    _coinKey.currentState?.burst(count: 8 + (e.coinCost ~/ 50).clamp(0, 16));
  }

  @override
  void dispose() {
    _glowCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final e = widget.event;
    if (e == null) return const SizedBox.shrink();

    final rarity = PremiumGiftCatalog2026.rarity(e.giftId);
    final glow = rarity.glowColor;
    final emojis = [
      PremiumGiftCatalog2026.emoji(e.giftId),
      '✨',
      '💖',
      '⭐',
    ];

    return IgnorePointer(
      child: Stack(
        fit: StackFit.expand,
        children: [
          AnimatedBuilder(
            animation: _glowCtrl,
            builder: (context, _) {
              return CustomPaint(
                painter: _NeonVignettePainter(
                  phase: _glowCtrl.value,
                  glow: glow,
                ),
                size: Size.infinite,
              );
            },
          ),
          Container(color: Colors.black.withValues(alpha: 0.48))
              .animate(key: ValueKey(e.id))
              .fadeIn(duration: 200.ms),
          FloatingGiftParticles(
            key: _particlesKey,
            emojis: emojis,
            spawnFromGiftId: e.giftId,
          ),
          GiftCoinBurstOverlay(key: _coinKey, active: true),
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _GlowTrailRing(glow: glow, animation: _glowCtrl),
                const SizedBox(height: 8),
                SizedBox(
                  width: 260,
                  height: 260,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      DecoratedBox(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          boxShadow: AppColors.glowShadow(glow, blur: 48),
                        ),
                        child: _GiftHero(giftId: e.giftId, event: e),
                      ),
                    ],
                  ),
                ),
                if (e.combo > 1) ...[
                  const SizedBox(height: 12),
                  _ComboBadge(combo: e.combo, glow: glow),
                ],
                const SizedBox(height: 14),
                _SenderBanner(event: e, glow: glow),
              ],
            ),
          )
              .animate(key: ValueKey('hero-${e.id}'))
              .fadeIn(duration: 280.ms)
              .scale(
                begin: const Offset(0.6, 0.6),
                end: const Offset(1, 1),
                curve: Curves.easeOutBack,
              ),
        ],
      ),
    );
  }
}

class _GiftHero extends StatelessWidget {
  const _GiftHero({required this.giftId, required this.event});

  final String giftId;
  final LiveGiftEvent event;

  @override
  Widget build(BuildContext context) {
    return GiftAnimationPlayer(
      giftId: giftId,
      event: event,
      size: 220,
      preferPremiumVisual: true,
    );
  }
}

class _ComboBadge extends StatelessWidget {
  const _ComboBadge({required this.combo, required this.glow});

  final int combo;
  final Color glow;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 10),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            glow.withValues(alpha: 0.5),
            AppColors.accentPink.withValues(alpha: 0.35),
          ],
        ),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: AppColors.coinGold.withValues(alpha: 0.7), width: 2),
        boxShadow: AppColors.glowShadow(AppColors.coinGold, blur: 20),
      ),
      child: Text(
        'COMBO x$combo',
        style: TextStyle(
          fontSize: 36,
          fontWeight: FontWeight.w900,
          letterSpacing: 1.2,
          foreground: Paint()
            ..shader = AppColors.brandGradient.createShader(
              const Rect.fromLTWH(0, 0, 200, 44),
            ),
          shadows: [Shadow(color: glow.withValues(alpha: 0.9), blurRadius: 18)],
        ),
      ),
    )
        .animate()
        .scale(
          begin: const Offset(0.3, 0.3),
          end: const Offset(1, 1),
          duration: 500.ms,
          curve: Curves.elasticOut,
        )
        .shimmer(duration: 1200.ms, color: Colors.white24);
  }
}

class _SenderBanner extends StatelessWidget {
  const _SenderBanner({required this.event, required this.glow});

  final LiveGiftEvent event;
  final Color glow;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: glow.withValues(alpha: 0.55)),
        boxShadow: AppColors.glowShadow(glow, blur: 14),
      ),
      child: Text(
        event.notificationText,
        textAlign: TextAlign.center,
        style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
      ),
    );
  }
}

class _GlowTrailRing extends StatelessWidget {
  const _GlowTrailRing({required this.glow, required this.animation});

  final Color glow;
  final Animation<double> animation;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, _) {
        return CustomPaint(
          size: const Size(280, 280),
          painter: _GlowRingPainter(phase: animation.value, glow: glow),
        );
      },
    );
  }
}

class _GlowRingPainter extends CustomPainter {
  _GlowRingPainter({required this.phase, required this.glow});

  final double phase;
  final Color glow;

  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2);
    final r = size.width * 0.42;
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..shader = SweepGradient(
        startAngle: phase * pi * 2,
        colors: [
          glow.withValues(alpha: 0.05),
          glow,
          AppColors.accentPink,
          glow.withValues(alpha: 0.05),
        ],
      ).createShader(Rect.fromCircle(center: c, radius: r))
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
    canvas.drawCircle(c, r, paint);
  }

  @override
  bool shouldRepaint(covariant _GlowRingPainter old) =>
      old.phase != phase || old.glow != glow;
}

class _NeonVignettePainter extends CustomPainter {
  _NeonVignettePainter({required this.phase, required this.glow});

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
            -0.3 + sin(phase * pi * 2) * 0.2,
            -0.2 + cos(phase * pi * 2) * 0.15,
          ),
          radius: 1.1,
          colors: [
            glow.withValues(alpha: 0.22),
            AppColors.accentPurple.withValues(alpha: 0.12),
            Colors.transparent,
          ],
        ).createShader(rect),
    );
  }

  @override
  bool shouldRepaint(covariant _NeonVignettePainter old) =>
      old.phase != phase || old.glow != glow;
}
