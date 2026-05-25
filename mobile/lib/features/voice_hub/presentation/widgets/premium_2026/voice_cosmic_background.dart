import 'dart:math' as math;
import 'dart:ui';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../theme/voice_room_tokens.dart';

/// Kozmik / galaksi arka plan + yüzen parçacıklar.
class VoiceCosmicBackground extends StatefulWidget {
  const VoiceCosmicBackground({super.key, this.imageUrl});

  final String? imageUrl;

  @override
  State<VoiceCosmicBackground> createState() => _VoiceCosmicBackgroundState();
}

class _VoiceCosmicBackgroundState extends State<VoiceCosmicBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _drift;

  @override
  void initState() {
    super.initState();
    _drift = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 18),
    )..repeat();
  }

  @override
  void dispose() {
    _drift.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        const DecoratedBox(
          decoration: BoxDecoration(gradient: VoiceRoomTokens.cosmicGradient),
        ),
        if (widget.imageUrl != null && widget.imageUrl!.isNotEmpty)
          CachedNetworkImage(
            imageUrl: widget.imageUrl!,
            fit: BoxFit.cover,
            color: Colors.black.withValues(alpha: 0.42),
            colorBlendMode: BlendMode.darken,
          ),
        Positioned(
          top: -80,
          right: -40,
          child: _orb(VoiceRoomTokens.neonPurple, 220),
        ),
        Positioned(
          bottom: 120,
          left: -60,
          child: _orb(VoiceRoomTokens.neonPink, 180),
        ),
        Positioned(
          top: MediaQuery.sizeOf(context).height * 0.35,
          left: MediaQuery.sizeOf(context).width * 0.2,
          child: _orb(VoiceRoomTokens.neonBlue, 120, opacity: 0.2),
        ),
        AnimatedBuilder(
          animation: _drift,
          builder: (context, _) => CustomPaint(
            painter: _ParticlePainter(progress: _drift.value),
            size: Size.infinite,
          ),
        ),
        ClipRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 0.5, sigmaY: 0.5),
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.08),
                    VoiceRoomTokens.bgDeep.withValues(alpha: 0.78),
                  ],
                  stops: const [0.0, 0.92],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _orb(Color color, double size, {double opacity = 0.35}) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [
            color.withValues(alpha: opacity),
            Colors.transparent,
          ],
        ),
      ),
    );
  }
}

class _ParticlePainter extends CustomPainter {
  _ParticlePainter({required this.progress});

  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final rnd = math.Random(42);
    for (var i = 0; i < 36; i++) {
      final baseX = rnd.nextDouble() * size.width;
      final baseY = rnd.nextDouble() * size.height;
      final drift = math.sin((progress + i * 0.07) * math.pi * 2) * 8;
      final paint = Paint()
        ..color = Colors.white.withValues(alpha: 0.08 + rnd.nextDouble() * 0.12)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);
      canvas.drawCircle(
        Offset(baseX + drift, baseY - drift * 0.5),
        0.8 + rnd.nextDouble() * 1.6,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _ParticlePainter oldDelegate) =>
      oldDelegate.progress != progress;
}
