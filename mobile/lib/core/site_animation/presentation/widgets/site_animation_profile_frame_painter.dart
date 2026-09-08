import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../domain/site_animation_tier.dart';
import '../../../../features/voice_hub/presentation/theme/voice_room_tokens.dart';

/// Profil çerçevesi — `animationId` bazlı özgün native loop.
class SiteAnimationProfileFramePainter extends CustomPainter {
  SiteAnimationProfileFramePainter({
    required this.animationId,
    required this.tier,
    required this.phase,
  });

  final String? animationId;
  final SiteAnimationTier tier;
  final double phase;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.shortestSide / 2 - 2;
    final id = animationId ?? '';

    final paint = Paint()..style = PaintingStyle.stroke;
    final baseColor = _colorFor(id, tier);

    paint.strokeWidth = 3;
    paint.color = baseColor.withValues(alpha: 0.85);
    canvas.drawCircle(center, radius, paint);

    paint.style = PaintingStyle.fill;
    switch (true) {
      case _ when id.contains('fire'):
        _paintFire(canvas, center, radius, phase, paint);
      case _ when id.contains('lightning'):
        _paintLightning(canvas, center, radius, phase, paint);
      case _ when id.contains('galaxy') || id.contains('cosmic'):
        _paintGalaxy(canvas, center, radius, phase, paint);
      case _ when id.contains('dragon') || id.contains('emperor'):
        _paintDragon(canvas, center, radius, phase, paint);
      case _ when id.contains('crystal'):
        _paintCrystal(canvas, center, radius, phase, paint);
      case _ when id.contains('admin'):
        _paintAdmin(canvas, center, radius, phase, paint);
      case _ when id.contains('neon'):
        _paintNeon(canvas, center, radius, phase, paint);
      default:
        _paintPulseRing(canvas, center, radius, phase, baseColor, paint);
    }
  }

  static Color _colorFor(String id, SiteAnimationTier tier) {
    if (id.contains('gold') || id.contains('fire')) return VoiceRoomTokens.gold;
    if (id.contains('diamond') || id.contains('crystal') || id.contains('lightning')) {
      return const Color(0xFF00D9D9);
    }
    if (id.contains('admin')) return const Color(0xFFFF5252);
    return switch (tier) {
      SiteAnimationTier.gold => VoiceRoomTokens.gold,
      SiteAnimationTier.diamond => const Color(0xFF00D9D9),
      SiteAnimationTier.svip => const Color(0xFFFF6EC7),
      SiteAnimationTier.vip => VoiceRoomTokens.neonPurple,
      SiteAnimationTier.admin => const Color(0xFFFF5252),
      _ => VoiceRoomTokens.neonPurple,
    };
  }

  void _paintPulseRing(
    Canvas canvas,
    Offset center,
    double radius,
    double phase,
    Color color,
    Paint paint,
  ) {
    paint.style = PaintingStyle.stroke;
    paint.strokeWidth = 2;
    paint.color = color.withValues(alpha: 0.35 + math.sin(phase * math.pi * 2) * 0.2);
    canvas.drawCircle(center, radius + 4, paint);
  }

  void _paintFire(Canvas canvas, Offset c, double r, double phase, Paint paint) {
    paint.color = const Color(0xFFFF5722).withValues(alpha: 0.45);
    for (var i = 0; i < 6; i++) {
      final a = phase * math.pi * 2 + i;
      canvas.drawCircle(
        Offset(c.dx + math.cos(a) * r, c.dy + math.sin(a) * r),
        3 + math.sin(phase * 6 + i),
        paint,
      );
    }
  }

  void _paintLightning(Canvas canvas, Offset c, double r, double phase, Paint paint) {
    paint.color = const Color(0xFF00D9D9).withValues(alpha: 0.6);
    paint.style = PaintingStyle.stroke;
    paint.strokeWidth = 2;
    final path = Path()
      ..moveTo(c.dx + r * 0.2, c.dy - r)
      ..lineTo(c.dx, c.dy)
      ..lineTo(c.dx + r * 0.15, c.dy);
    canvas.drawPath(path, paint);
  }

  void _paintGalaxy(Canvas canvas, Offset c, double r, double phase, Paint paint) {
    paint.color = const Color(0xFFC026D3).withValues(alpha: 0.5);
    paint.style = PaintingStyle.stroke;
    paint.strokeWidth = 2;
    canvas.drawArc(
      Rect.fromCircle(center: c, radius: r),
      phase * math.pi,
      math.pi * 1.4,
      false,
      paint,
    );
  }

  void _paintDragon(Canvas canvas, Offset c, double r, double phase, Paint paint) {
    paint.color = const Color(0xFFFF6EC7).withValues(alpha: 0.35);
    canvas.drawCircle(c, r * (0.9 + math.sin(phase * math.pi * 2) * 0.05), paint);
  }

  void _paintCrystal(Canvas canvas, Offset c, double r, double phase, Paint paint) {
    paint.color = const Color(0xFF7DF9FF).withValues(alpha: 0.5);
    for (var i = 0; i < 4; i++) {
      final a = phase * math.pi + i * math.pi / 2;
      canvas.drawCircle(
        Offset(c.dx + math.cos(a) * r * 0.85, c.dy + math.sin(a) * r * 0.85),
        2.5,
        paint,
      );
    }
  }

  void _paintAdmin(Canvas canvas, Offset c, double r, double phase, Paint paint) {
    paint.color = const Color(0xFF8B4DFF).withValues(alpha: 0.45);
    paint.style = PaintingStyle.stroke;
    paint.strokeWidth = 2;
    canvas.drawArc(
      Rect.fromCircle(center: c, radius: r),
      -phase * math.pi,
      math.pi,
      false,
      paint,
    );
  }

  void _paintNeon(Canvas canvas, Offset c, double r, double phase, Paint paint) {
    paint.style = PaintingStyle.stroke;
    paint.strokeWidth = 2.5;
    paint.color = VoiceRoomTokens.neonPurple.withValues(alpha: 0.5 + phase * 0.3);
    canvas.drawCircle(c, r, paint);
    paint.color = const Color(0xFF00D9D9).withValues(alpha: 0.35);
    canvas.drawCircle(c, r - 5, paint);
  }

  @override
  bool shouldRepaint(covariant SiteAnimationProfileFramePainter oldDelegate) =>
      oldDelegate.phase != phase ||
      oldDelegate.tier != tier ||
      oldDelegate.animationId != animationId;
}
