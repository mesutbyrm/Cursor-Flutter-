import 'dart:math' as math;

import 'package:canlifal_social/core/performance/animation_perf.dart';
import 'package:flutter/material.dart';

/// Sesli oda — hafif yüzen parçacıklar (RepaintBoundary + önceden hesaplanmış yörüngeler).
class VoiceRoomParticles extends StatefulWidget {
  const VoiceRoomParticles({super.key});

  @override
  State<VoiceRoomParticles> createState() => _VoiceRoomParticlesState();
}

class _VoiceRoomParticlesState extends State<VoiceRoomParticles>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final PrecomputedDriftParticles _field;

  @override
  void initState() {
    super.initState();
    _field = PrecomputedDriftParticles.generate(seed: 11, count: 24);
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 24),
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimationPerf.isolated(
      IgnorePointer(
        child: AnimationPerf.paintLayer(
          repaint: _ctrl,
          painter: _ParticlesPainter(_field, _ctrl),
        ),
      ),
    );
  }
}

class _ParticlesPainter extends CustomPainter {
  _ParticlesPainter(this.field, this.tick) : super(repaint: tick);

  final PrecomputedDriftParticles field;
  final Animation<double> tick;

  @override
  void paint(Canvas canvas, Size size) {
    final progress = tick.value;
    for (var i = 0; i < field.points.length; i++) {
      final p = field.points[i];
      final drift = math.sin((progress + i * 0.08) * math.pi * 2) * 6;
      final paint = Paint()
        ..color = Colors.white.withValues(alpha: p.alpha)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);
      canvas.drawCircle(
        Offset(p.x * size.width + drift, p.y * size.height - drift),
        p.radius,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _ParticlesPainter old) => true;
}
