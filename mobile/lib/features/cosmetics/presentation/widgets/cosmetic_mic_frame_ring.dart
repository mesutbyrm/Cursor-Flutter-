import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../domain/cosmetic_effect_kind.dart';
import '../../domain/cosmetic_item.dart';

/// Mikrofon koltuğu — kozmetik halka çerçevesi (yalnızca kendi kullanıcı).
class CosmeticMicFrameRing extends StatefulWidget {
  const CosmeticMicFrameRing({
    super.key,
    required this.item,
    required this.size,
    required this.child,
    this.micOpen = true,
  });

  final CosmeticItem item;
  final double size;
  final Widget child;
  final bool micOpen;

  @override
  State<CosmeticMicFrameRing> createState() => _CosmeticMicFrameRingState();
}

class _CosmeticMicFrameRingState extends State<CosmeticMicFrameRing>
    with SingleTickerProviderStateMixin {
  late final AnimationController _spin;

  @override
  void initState() {
    super.initState();
    _spin = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();
  }

  @override
  void dispose() {
    _spin.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.micOpen) return widget.child;

    final colors = _ringColors(widget.item.effectKind);
    return SizedBox(
      width: widget.size + 8,
      height: widget.size + 8,
      child: Stack(
        alignment: Alignment.center,
        children: [
          AnimatedBuilder(
            animation: _spin,
            builder: (context, _) {
              return CustomPaint(
                size: Size.square(widget.size + 8),
                painter: _MicRingPainter(
                  colors: colors,
                  phase: _spin.value,
                  kind: widget.item.effectKind,
                ),
              );
            },
          ),
          widget.child,
        ],
      ),
    );
  }

  List<Color> _ringColors(CosmeticEffectKind kind) => switch (kind) {
        CosmeticEffectKind.goldParticles => [
            const Color(0xFFFFD54F),
            const Color(0xFFFF8F00),
            const Color(0xFFFFF3B0),
          ],
        CosmeticEffectKind.neonGlow => [
            const Color(0xFF7C4DFF),
            const Color(0xFF00E5FF),
            const Color(0xFFE040FB),
          ],
        CosmeticEffectKind.fire => [
            const Color(0xFFFF5722),
            const Color(0xFFFF9800),
            const Color(0xFFFFEB3B),
          ],
        _ => [
            const Color(0xFF7C4DFF),
            const Color(0xFF00E5FF),
          ],
      };
}

class _MicRingPainter extends CustomPainter {
  _MicRingPainter({
    required this.colors,
    required this.phase,
    required this.kind,
  });

  final List<Color> colors;
  final double phase;
  final CosmeticEffectKind kind;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 2;
    final stroke = kind == CosmeticEffectKind.fire ? 3.5 : 2.8;
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..shader = SweepGradient(
        colors: [...colors, colors.first],
        transform: GradientRotation(phase * 2 * math.pi),
      ).createShader(Rect.fromCircle(center: center, radius: radius));
    canvas.drawCircle(center, radius, paint);
  }

  @override
  bool shouldRepaint(covariant _MicRingPainter old) =>
      old.phase != phase || old.kind != kind;
}
