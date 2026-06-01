import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Sesli oda — hafif yüzen parçacıklar (RepaintBoundary içinde).
class VoiceRoomParticles extends StatefulWidget {
  const VoiceRoomParticles({super.key});

  @override
  State<VoiceRoomParticles> createState() => _VoiceRoomParticlesState();
}

class _VoiceRoomParticlesState extends State<VoiceRoomParticles>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
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
    return RepaintBoundary(
      child: IgnorePointer(
        child: AnimatedBuilder(
          animation: _ctrl,
          builder: (_, __) => CustomPaint(
            painter: _ParticlesPainter(_ctrl.value),
            size: Size.infinite,
          ),
        ),
      ),
    );
  }
}

class _ParticlesPainter extends CustomPainter {
  _ParticlesPainter(this.progress);

  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final rnd = math.Random(11);
    for (var i = 0; i < 24; i++) {
      final bx = rnd.nextDouble() * size.width;
      final by = rnd.nextDouble() * size.height * 0.55;
      final drift = math.sin((progress + i * 0.08) * math.pi * 2) * 6;
      final paint = Paint()
        ..color = Colors.white.withValues(alpha: 0.04 + rnd.nextDouble() * 0.08)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);
      canvas.drawCircle(Offset(bx + drift, by - drift), 1.2 + rnd.nextDouble(), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _ParticlesPainter old) => old.progress != progress;
}
