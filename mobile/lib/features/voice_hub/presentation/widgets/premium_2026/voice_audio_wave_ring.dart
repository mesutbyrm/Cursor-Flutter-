import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../theme/voice_room_tokens.dart';

/// Konuşan kullanıcı için nabız dalga halkası (CustomPainter).
class VoiceAudioWaveRing extends StatefulWidget {
  const VoiceAudioWaveRing({
    super.key,
    required this.size,
    required this.active,
    this.child,
    this.goldHost = false,
  });

  final double size;
  final bool active;
  final bool goldHost;
  final Widget? child;

  @override
  State<VoiceAudioWaveRing> createState() => _VoiceAudioWaveRingState();
}

class _VoiceAudioWaveRingState extends State<VoiceAudioWaveRing>
    with SingleTickerProviderStateMixin {
  late final AnimationController _wave;

  @override
  void initState() {
    super.initState();
    _wave = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );
    _sync();
  }

  @override
  void didUpdateWidget(covariant VoiceAudioWaveRing oldWidget) {
    super.didUpdateWidget(oldWidget);
    _sync();
  }

  void _sync() {
    if (widget.active) {
      _wave.repeat();
    } else {
      _wave.stop();
      _wave.value = 0;
    }
  }

  @override
  void dispose() {
    _wave.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ringSize = widget.size + (widget.goldHost ? 28 : 20);
    return SizedBox(
      width: ringSize,
      height: ringSize,
      child: AnimatedBuilder(
        animation: _wave,
        builder: (context, child) {
          return CustomPaint(
            painter: _WaveRingPainter(
              progress: _wave.value,
              active: widget.active,
              gold: widget.goldHost,
            ),
            child: Center(child: child),
          );
        },
        child: widget.child,
      ),
    );
  }
}

class _WaveRingPainter extends CustomPainter {
  _WaveRingPainter({
    required this.progress,
    required this.active,
    required this.gold,
  });

  final double progress;
  final bool active;
  final bool gold;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final baseR = size.width / 2 - 6;

    final ringPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = gold ? 3.5 : 2.5
      ..shader = (gold ? VoiceRoomTokens.goldRing : VoiceRoomTokens.neonRing)
          .createShader(Rect.fromCircle(center: center, radius: baseR));

    canvas.drawCircle(center, baseR, ringPaint);

    if (!active) return;

    for (var i = 0; i < 3; i++) {
      final phase = (progress + i * 0.33) % 1.0;
      final expand = 4 + phase * 14;
      final alpha = (1 - phase) * 0.45;
      final paint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = (gold ? VoiceRoomTokens.gold : VoiceRoomTokens.neonPink)
            .withValues(alpha: alpha);
      canvas.drawCircle(center, baseR + expand, paint);
    }

    // Ses dalgası çubukları (alt yay)
    final barCount = 12;
    for (var i = 0; i < barCount; i++) {
      final t = i / (barCount - 1);
      final angle = math.pi * 0.85 + t * math.pi * 0.3;
      final amp = 4 + math.sin((progress * math.pi * 2) + i) * 6;
      final inner = baseR - 2;
      final outer = inner + amp;
      final p1 = Offset(
        center.dx + inner * math.cos(angle),
        center.dy + inner * math.sin(angle),
      );
      final p2 = Offset(
        center.dx + outer * math.cos(angle),
        center.dy + outer * math.sin(angle),
      );
      canvas.drawLine(
        p1,
        p2,
        Paint()
          ..strokeWidth = 2
          ..strokeCap = StrokeCap.round
          ..color = VoiceRoomTokens.neonBlue.withValues(alpha: 0.7),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _WaveRingPainter oldDelegate) =>
      oldDelegate.progress != progress ||
      oldDelegate.active != active ||
      oldDelegate.gold != gold;
}
