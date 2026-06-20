import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';

import 'ultra_fortune_tokens.dart';

/// Devasa animasyonlu kristal küre — galaksi, nefes, 20 sn dönüş.
class UltraFortuneCrystalBall extends StatefulWidget {
  const UltraFortuneCrystalBall({super.key, this.size = 200});

  final double size;

  @override
  State<UltraFortuneCrystalBall> createState() => _UltraFortuneCrystalBallState();
}

class _UltraFortuneCrystalBallState extends State<UltraFortuneCrystalBall>
    with TickerProviderStateMixin {
  late final AnimationController _rotate;
  late final AnimationController _breathe;

  @override
  void initState() {
    super.initState();
    _rotate = AnimationController(
      vsync: this,
      duration: UltraFortuneTokens.crystalRotation,
    )..repeat();
    _breathe = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _rotate.dispose();
    _breathe.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.size;
    final breatheScale = 1.0 + _breathe.value * 0.04;

    return AnimatedBuilder(
      animation: Listenable.merge([_rotate, _breathe]),
      builder: (_, __) {
        return Transform.scale(
          scale: breatheScale,
          child: SizedBox(
            width: s,
            height: s * 1.12,
            child: CustomPaint(
              painter: _CrystalBallPainter(
                rotation: _rotate.value,
                breathe: _breathe.value,
              ),
            ),
          ),
        );
      },
    );
  }
}

class _CrystalBallPainter extends CustomPainter {
  _CrystalBallPainter({required this.rotation, required this.breathe});

  final double rotation;
  final double breathe;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final center = Offset(w * 0.5, h * 0.44);
    final ballR = w * 0.38;

    // Volumetric glow
    for (var i = 3; i >= 1; i--) {
      canvas.drawCircle(
        center,
        ballR * (1.15 + i * 0.12),
        Paint()
          ..shader = RadialGradient(
            colors: [
              UltraFortuneTokens.electricPurple.withValues(alpha: 0.12 / i),
              Colors.transparent,
            ],
          ).createShader(Rect.fromCircle(center: center, radius: ballR * 2)),
      );
    }

    // Golden pedestal
    final baseY = h * 0.86;
    final basePath = Path()
      ..moveTo(w * 0.28, baseY)
      ..quadraticBezierTo(w * 0.5, baseY - h * 0.06, w * 0.72, baseY)
      ..lineTo(w * 0.68, h * 0.98)
      ..quadraticBezierTo(w * 0.5, h * 1.02, w * 0.32, h * 0.98)
      ..close();
    canvas.drawPath(
      basePath,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFFFFD67A),
            Color(0xFFB8860B),
            Color(0xFF3D2A14),
          ],
        ).createShader(Rect.fromLTWH(0, baseY - 10, w, h)),
    );
    canvas.drawPath(
      basePath,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2
        ..color = UltraFortuneTokens.metallicGold.withValues(alpha: 0.55),
    );

    // Ball shadow
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(center.dx, h * 0.92),
        width: w * 0.42,
        height: h * 0.06,
      ),
      Paint()
        ..color = Colors.black.withValues(alpha: 0.45)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12),
    );

    // Inner galaxy (clipped to sphere)
    canvas.save();
    canvas.clipPath(Path()..addOval(Rect.fromCircle(center: center, radius: ballR)));
    _paintGalaxy(canvas, center, ballR, rotation);
    canvas.restore();

    // Glass sphere
    final glassPaint = Paint()
      ..shader = RadialGradient(
        center: const Alignment(-0.3, -0.45),
        radius: 1.15,
        colors: [
          Colors.white.withValues(alpha: 0.18),
          UltraFortuneTokens.softLilac.withValues(alpha: 0.35),
          UltraFortuneTokens.electricPurple.withValues(alpha: 0.55),
          const Color(0xFF1E0A3A).withValues(alpha: 0.92),
        ],
        stops: const [0.0, 0.25, 0.6, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: ballR));
    canvas.drawCircle(center, ballR, glassPaint);

    // Caustic refraction arcs
    for (var i = 0; i < 3; i++) {
      final angle = rotation * math.pi * 2 + i * 1.2;
      final arcCenter = center +
          Offset(math.cos(angle) * ballR * 0.35, math.sin(angle) * ballR * 0.28);
      canvas.drawArc(
        Rect.fromCircle(center: arcCenter, radius: ballR * 0.45),
        angle,
        0.8,
        false,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5
          ..color = Colors.white.withValues(alpha: 0.08 + breathe * 0.06),
      );
    }

    // Specular highlight
    canvas.drawOval(
      Rect.fromCenter(
        center: center.translate(-ballR * 0.32, -ballR * 0.38),
        width: ballR * 0.42,
        height: ballR * 0.26,
      ),
      Paint()
        ..shader = RadialGradient(
          colors: [
            Colors.white.withValues(alpha: 0.65),
            Colors.white.withValues(alpha: 0.0),
          ],
        ).createShader(Rect.fromCircle(
          center: center.translate(-ballR * 0.32, -ballR * 0.38),
          radius: ballR * 0.25,
        )),
    );

    // Rim light
    canvas.drawCircle(
      center,
      ballR,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..shader = SweepGradient(
          colors: [
            UltraFortuneTokens.metallicGold.withValues(alpha: 0.5),
            UltraFortuneTokens.softLilac.withValues(alpha: 0.3),
            Colors.white.withValues(alpha: 0.2),
            UltraFortuneTokens.metallicGold.withValues(alpha: 0.45),
          ],
          transform: GradientRotation(rotation * math.pi * 2),
        ).createShader(Rect.fromCircle(center: center, radius: ballR)),
    );
  }

  void _paintGalaxy(Canvas canvas, Offset center, double ballR, double rot) {
    final angle = rot * math.pi * 2;

    // Spiral galaxy core
    canvas.drawCircle(
      center,
      ballR * 0.18,
      Paint()
        ..shader = RadialGradient(
          colors: [
            Colors.white.withValues(alpha: 0.9),
            UltraFortuneTokens.softLilac.withValues(alpha: 0.8),
            UltraFortuneTokens.electricPurple.withValues(alpha: 0.4),
            Colors.transparent,
          ],
        ).createShader(Rect.fromCircle(center: center, radius: ballR * 0.35)),
    );

    // Spiral arms
    final armPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    for (var arm = 0; arm < 2; arm++) {
      final path = Path();
      for (var t = 0.0; t <= 1.0; t += 0.02) {
        final a = angle + arm * math.pi + t * math.pi * 3;
        final r = ballR * 0.08 + t * ballR * 0.55;
        final p = center + Offset(math.cos(a) * r, math.sin(a) * r * 0.7);
        if (t == 0) {
          path.moveTo(p.dx, p.dy);
        } else {
          path.lineTo(p.dx, p.dy);
        }
      }
      armPaint.color = UltraFortuneTokens.softLilac.withValues(alpha: 0.35);
      canvas.drawPath(path, armPaint);
    }

    // Constellation stars
    final starRnd = math.Random(13);
    for (var i = 0; i < 18; i++) {
      final a = angle + starRnd.nextDouble() * math.pi * 2;
      final r = ballR * (0.15 + starRnd.nextDouble() * 0.55);
      final p = center + Offset(math.cos(a) * r, math.sin(a) * r * 0.75);
      canvas.drawCircle(
        p,
        0.8 + starRnd.nextDouble() * 1.5,
        Paint()..color = Colors.white.withValues(alpha: 0.5 + starRnd.nextDouble() * 0.5),
      );
    }

    // Crescent moon
    final moonAngle = angle + math.pi * 0.6;
    final moonCenter = center +
        Offset(math.cos(moonAngle) * ballR * 0.35, math.sin(moonAngle) * ballR * 0.25);
    canvas.drawCircle(
      moonCenter,
      ballR * 0.12,
      Paint()..color = UltraFortuneTokens.metallicGold.withValues(alpha: 0.85),
    );
    canvas.drawCircle(
      moonCenter.translate(ballR * 0.05, -ballR * 0.02),
      ballR * 0.1,
      Paint()..color = const Color(0xFF2A1050),
    );

    // Energy streams
    for (var i = 0; i < 4; i++) {
      final streamAngle = angle + i * math.pi / 2;
      final streamPath = Path()
        ..moveTo(center.dx, center.dy)
        ..quadraticBezierTo(
          center.dx + math.cos(streamAngle) * ballR * 0.5,
          center.dy + math.sin(streamAngle) * ballR * 0.35,
          center.dx + math.cos(streamAngle + 0.4) * ballR * 0.7,
          center.dy + math.sin(streamAngle + 0.4) * ballR * 0.5,
        );
      canvas.drawPath(
        streamPath,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5
          ..color = UltraFortuneTokens.electricPurple.withValues(alpha: 0.25)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _CrystalBallPainter old) =>
      old.rotation != rotation || old.breathe != breathe;
}
