import 'dart:math' as math;

import 'package:flutter/material.dart';
import '../../domain/vip_tier.dart';
import '../theme/vip_gold_tokens.dart';
import 'vip_badge.dart';

/// Özel giriş animasyonu — odaya katılımda tam ekran FX.
class VipEntranceOverlay extends StatefulWidget {
  const VipEntranceOverlay({
    super.key,
    required this.tier,
    required this.userName,
    this.onFinished,
  });

  final VipTier tier;
  final String userName;
  final VoidCallback? onFinished;

  @override
  State<VipEntranceOverlay> createState() => VipEntranceOverlayState();
}

class VipEntranceOverlayState extends State<VipEntranceOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..forward().then((_) {
        if (mounted) widget.onFinished?.call();
      });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.tier.hasEntranceFx) return const SizedBox.shrink();

    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _ctrl,
        builder: (context, _) {
          final t = Curves.easeOutCubic.transform(_ctrl.value);
          return Stack(
            fit: StackFit.expand,
            children: [
              Container(
                color: Colors.black.withValues(alpha: (1 - t) * 0.75),
              ),
              CustomPaint(
                painter: _ParticlePainter(phase: _ctrl.value),
                size: Size.infinite,
              ),
              Center(
                child: Opacity(
                  opacity: (1 - (t - 0.5).abs() * 2).clamp(0.0, 1.0),
                  child: Transform.scale(
                    scale: 0.7 + t * 0.35,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.flight_land_rounded,
                          size: 64,
                          color: VipGoldTokens.goldMid,
                          shadows: VipGoldTokens.goldGlow(),
                        ),
                        const SizedBox(height: 12),
                        ShaderMask(
                          shaderCallback: (b) =>
                              VipGoldTokens.goldLuxury.createShader(b),
                          child: Text(
                            widget.userName,
                            style: const TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'odaya giriş yaptı',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.8),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 14),
                        VipBadge(tier: widget.tier, animate: true),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _ParticlePainter extends CustomPainter {
  _ParticlePainter({required this.phase});

  final double phase;

  @override
  void paint(Canvas canvas, Size size) {
    final rand = math.Random(42);
    for (var i = 0; i < 40; i++) {
      final x = rand.nextDouble() * size.width;
      final y = size.height * (1 - ((phase + i * 0.02) % 1.0));
      canvas.drawCircle(
        Offset(x, y),
        2 + rand.nextDouble() * 3,
        Paint()..color = VipGoldTokens.goldMid.withValues(alpha: 0.5 * (1 - phase)),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _ParticlePainter old) => old.phase != phase;
}
