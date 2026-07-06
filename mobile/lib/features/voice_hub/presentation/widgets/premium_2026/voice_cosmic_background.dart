import 'dart:math' as math;

import 'package:canlifal_social/core/images/canlifal_network_image.dart';
import 'package:flutter/material.dart';

import '../../theme/voice_room_tokens.dart';

/// Kozmik / galaksi arka plan + yüzen parçacıklar.
class VoiceCosmicBackground extends StatefulWidget {
  const VoiceCosmicBackground({
    super.key,
    this.imageUrl,
    this.showParticles = false,
  });

  final String? imageUrl;
  final bool showParticles;

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
    final hasImage = widget.imageUrl != null && widget.imageUrl!.isNotEmpty;

    // Özel arka plan görseli: karartma/blend YOK — canlı ve gerçekçi kalsın.
    // Yalnızca metin/koltuk okunurluğu için ince bir üst+alt geçiş uygulanır,
    // görselin ortası tamamen açık kalır. Neon orblar ve ağır katman yok.
    if (hasImage) {
      return LayoutBuilder(
        builder: (context, constraints) {
          final w = constraints.maxWidth;
          final h = constraints.maxHeight;
          return Stack(
            fit: StackFit.expand,
            children: [
              const DecoratedBox(
                decoration: BoxDecoration(gradient: VoiceRoomTokens.cosmicGradient),
              ),
              CanlifalNetworkImage(
                key: ValueKey(widget.imageUrl),
                url: widget.imageUrl!,
                width: w,
                height: h,
                thumbnailWidth: 720,
                fit: BoxFit.cover,
                fadeIn: false,
                placeholder: const DecoratedBox(
                  decoration:
                      BoxDecoration(gradient: VoiceRoomTokens.cosmicGradient),
                ),
                errorWidget: const DecoratedBox(
                  decoration:
                      BoxDecoration(gradient: VoiceRoomTokens.cosmicGradient),
                ),
              ),
              const IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Color(0x33000000),
                        Color(0x00000000),
                        Color(0x00000000),
                        Color(0x59000000),
                      ],
                      stops: [0.0, 0.22, 0.72, 1.0],
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      );
    }

    // Görsel yok — varsayılan kozmik görünüm (orblar + ince alt geçiş).
    return Stack(
      fit: StackFit.expand,
      children: [
        const DecoratedBox(
          decoration: BoxDecoration(gradient: VoiceRoomTokens.cosmicGradient),
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
        if (widget.showParticles)
          AnimatedBuilder(
            animation: _drift,
            builder: (context, _) => CustomPaint(
              painter: _ParticlePainter(progress: _drift.value),
              size: Size.infinite,
            ),
          ),
        DecoratedBox(
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
