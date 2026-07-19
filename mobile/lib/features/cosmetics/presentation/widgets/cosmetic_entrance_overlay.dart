import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../domain/cosmetic_effect_kind.dart';

/// Odaya giriş — tam ekran kozmetik animasyonu.
class CosmeticEntranceOverlay extends StatefulWidget {
  const CosmeticEntranceOverlay({
    super.key,
    required this.userName,
    required this.effectKind,
    this.onFinished,
  });

  final String userName;
  final CosmeticEffectKind effectKind;
  final VoidCallback? onFinished;

  @override
  State<CosmeticEntranceOverlay> createState() =>
      _CosmeticEntranceOverlayState();
}

class _CosmeticEntranceOverlayState extends State<CosmeticEntranceOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2800),
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
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _ctrl,
        builder: (context, _) {
          final t = Curves.easeOutCubic.transform(_ctrl.value);
          return Stack(
            fit: StackFit.expand,
            children: [
              Container(color: Colors.black.withValues(alpha: (1 - t) * 0.8)),
              CustomPaint(
                painter: _EntrancePainter(
                  kind: widget.effectKind,
                  phase: _ctrl.value,
                ),
                size: Size.infinite,
              ),
              Center(
                child: Opacity(
                  opacity: (1 - (t - 0.45).abs() * 2.2).clamp(0.0, 1.0),
                  child: Transform.scale(
                    scale: 0.65 + t * 0.4,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _iconFor(widget.effectKind),
                          size: 72,
                          color: _colorFor(widget.effectKind),
                          shadows: [
                            Shadow(
                              color: _colorFor(widget.effectKind)
                                  .withValues(alpha: 0.8),
                              blurRadius: 24,
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        Text(
                          widget.userName,
                          style: const TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'odaya giriş yaptı',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.75),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
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

  IconData _iconFor(CosmeticEffectKind k) => switch (k) {
        CosmeticEffectKind.entranceDragon => Icons.whatshot_rounded,
        CosmeticEffectKind.entranceMeteor => Icons.brightness_2_rounded,
        CosmeticEffectKind.entranceWings => Icons.air_rounded,
        CosmeticEffectKind.entranceAngel => Icons.auto_awesome_rounded,
        CosmeticEffectKind.entranceFireworks => Icons.celebration_rounded,
        CosmeticEffectKind.entranceCrown => Icons.emoji_events_rounded,
        CosmeticEffectKind.entranceGalaxy => Icons.hub_rounded,
        CosmeticEffectKind.entranceGoldRain => Icons.water_drop_rounded,
        _ => Icons.stars_rounded,
      };

  Color _colorFor(CosmeticEffectKind k) => switch (k) {
        CosmeticEffectKind.entranceDragon => const Color(0xFFFF5722),
        CosmeticEffectKind.entranceMeteor => const Color(0xFFFFEB3B),
        CosmeticEffectKind.entranceWings => const Color(0xFF80DEEA),
        CosmeticEffectKind.entranceAngel => Colors.white,
        CosmeticEffectKind.entranceFireworks => const Color(0xFFFF4081),
        CosmeticEffectKind.entranceCrown => const Color(0xFFFFD54F),
        CosmeticEffectKind.entranceGalaxy => const Color(0xFF7C4DFF),
        CosmeticEffectKind.entranceGoldRain => const Color(0xFFFFD54F),
        _ => const Color(0xFFB832FF),
      };
}

class _EntrancePainter extends CustomPainter {
  _EntrancePainter({required this.kind, required this.phase});

  final CosmeticEffectKind kind;
  final double phase;

  @override
  void paint(Canvas canvas, Size size) {
    final rand = math.Random(kind.index + 7);
    final count = switch (kind) {
      CosmeticEffectKind.entranceGalaxy => 60,
      CosmeticEffectKind.entranceGoldRain => 50,
      CosmeticEffectKind.entranceFireworks => 45,
      _ => 35,
    };
    for (var i = 0; i < count; i++) {
      final x = rand.nextDouble() * size.width;
      final y = size.height * (1 - ((phase + i * 0.015) % 1.0));
      final paint = Paint()
        ..color = _particleColor(kind).withValues(
          alpha: (0.15 + rand.nextDouble() * 0.5) * (1 - phase * 0.3),
        );
      canvas.drawCircle(
        Offset(x, y),
        1.5 + rand.nextDouble() * 4,
        paint,
      );
    }
  }

  Color _particleColor(CosmeticEffectKind k) => switch (k) {
        CosmeticEffectKind.entranceDragon => const Color(0xFFFF5722),
        CosmeticEffectKind.entranceMeteor => const Color(0xFFFFEB3B),
        CosmeticEffectKind.entranceGoldRain => const Color(0xFFFFD54F),
        CosmeticEffectKind.entranceGalaxy => const Color(0xFF7C4DFF),
        CosmeticEffectKind.entranceFireworks => const Color(0xFFFF4081),
        _ => const Color(0xFFB832FF),
      };

  @override
  bool shouldRepaint(covariant _EntrancePainter old) =>
      old.phase != phase || old.kind != kind;
}
