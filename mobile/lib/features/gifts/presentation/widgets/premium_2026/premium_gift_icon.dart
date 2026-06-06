import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:canlifal_social/core/theme/app_theme_colors.dart';

import '../../../domain/premium_gift_catalog_2026.dart';

/// Lottie/Rive yokken TikTok kalitesinde 3D-benzeri hediye illüstrasyonu.
class PremiumGiftIcon extends StatelessWidget {
  const PremiumGiftIcon({
    super.key,
    required this.giftId,
    this.size = 120,
    this.animate = true,
  });

  final String giftId;
  final double size;
  final bool animate;

  @override
  Widget build(BuildContext context) {
    final id = PremiumGiftCatalog2026.canonicalId(giftId) ?? giftId;
    final rarity = PremiumGiftCatalog2026.rarity(giftId);
    final glow = rarity.glowColor;

    CustomPainter? painter;
    switch (id) {
      case 'roket':
        painter = _RocketPainter(glow: glow);
      case 'galaksi':
        painter = _GalaxyPainter(glow: glow);
      case 'aslan':
        painter = _LionPainter(glow: glow);
      case 'araba':
        painter = _CarPainter(glow: glow);
      case 'elmas':
        painter = _DiamondPainter(glow: glow);
      case 'kalp':
        painter = _HeartPainter(glow: glow);
      case 'tac':
        painter = _CrownPainter(glow: glow);
      case 'yat':
        painter = _YachtPainter(glow: glow);
      default:
        painter = _GenericGiftPainter(
          emoji: PremiumGiftCatalog2026.emoji(giftId),
          glow: glow,
        );
    }

    final core = CustomPaint(
      size: Size.square(size),
      painter: painter,
    );

    if (!animate) return core;

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.92, end: 1.08),
      duration: const Duration(milliseconds: 1400),
      curve: Curves.easeInOut,
      builder: (_, scale, child) => Transform.scale(scale: scale, child: child),
      child: core,
    );
  }
}

sealed class _PremiumPainter extends CustomPainter {
  _PremiumPainter({required this.glow});

  final Color glow;

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _RocketPainter extends _PremiumPainter {
  _RocketPainter({required super.glow});

  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height * 0.48);
    final body = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Colors.white, AppThemeColors.accentPink, AppThemeColors.accentPurple],
      ).createShader(Rect.fromCenter(center: c, width: size.width * 0.35, height: size.height * 0.55));
    final path = Path()
      ..moveTo(c.dx, size.height * 0.12)
      ..lineTo(c.dx + size.width * 0.14, c.dy + size.height * 0.22)
      ..lineTo(c.dx + size.width * 0.1, size.height * 0.72)
      ..lineTo(c.dx, size.height * 0.78)
      ..lineTo(c.dx - size.width * 0.1, size.height * 0.72)
      ..lineTo(c.dx - size.width * 0.14, c.dy + size.height * 0.22)
      ..close();
    canvas.drawPath(path, body);
    canvas.drawCircle(
      Offset(c.dx, c.dy - size.height * 0.02),
      size.width * 0.06,
      Paint()..color = AppThemeColors.diamondBlue.withValues(alpha: 0.9),
    );
    final flame = Paint()
      ..shader = RadialGradient(
        colors: [AppThemeColors.coinGold, AppThemeColors.accentPink, Colors.transparent],
      ).createShader(Rect.fromLTWH(c.dx - 30, size.height * 0.72, 60, 50));
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(c.dx, size.height * 0.82),
        width: size.width * 0.22,
        height: size.height * 0.18,
      ),
      flame,
    );
    canvas.drawCircle(c, size.width * 0.42, Paint()..color = glow.withValues(alpha: 0.18)..maskFilter = const MaskFilter.blur(BlurStyle.normal, 24));
  }
}

class _GalaxyPainter extends _PremiumPainter {
  _GalaxyPainter({required super.glow});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final rand = math.Random(7);
    for (var i = 0; i < 48; i++) {
      final a = i / 48 * math.pi * 4;
      final r = size.width * (0.08 + (i % 12) / 48);
      final p = center + Offset(math.cos(a) * r, math.sin(a) * r * 0.55);
      canvas.drawCircle(
        p,
        1.2 + rand.nextDouble() * 2.2,
        Paint()..color = [AppThemeColors.accentPink, AppThemeColors.diamondBlue, Colors.white][i % 3].withValues(alpha: 0.5 + rand.nextDouble() * 0.5),
      );
    }
    final swirl = Paint()
      ..shader = SweepGradient(
        colors: [
          AppThemeColors.accentPurple,
          AppThemeColors.accentPink,
          AppThemeColors.diamondBlue,
          AppThemeColors.accentPurple,
        ],
      ).createShader(Rect.fromCircle(center: center, radius: size.width * 0.38))
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.08
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: size.width * 0.32),
      0,
      math.pi * 1.6,
      false,
      swirl,
    );
    canvas.drawCircle(center, size.width * 0.12, Paint()..color = Colors.white.withValues(alpha: 0.95));
    canvas.drawCircle(center, size.width * 0.4, Paint()..color = glow.withValues(alpha: 0.2)..maskFilter = const MaskFilter.blur(BlurStyle.normal, 28));
  }
}

class _LionPainter extends _PremiumPainter {
  _LionPainter({required super.glow});

  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height * 0.52);
    final gold = Paint()
      ..shader = LinearGradient(
        colors: [AppThemeColors.coinGold, const Color(0xFFB8860B)],
      ).createShader(Rect.fromCircle(center: c, radius: size.width * 0.38));
    canvas.drawCircle(c, size.width * 0.36, gold);
    for (var i = 0; i < 14; i++) {
      final a = i / 14 * math.pi * 2;
      final tip = c + Offset(math.cos(a) * size.width * 0.42, math.sin(a) * size.width * 0.42);
      canvas.drawLine(c, tip, Paint()..color = AppThemeColors.coinGold.withValues(alpha: 0.75)..strokeWidth = 5);
    }
    canvas.drawCircle(
      Offset(c.dx - size.width * 0.1, c.dy - size.height * 0.04),
      size.width * 0.05,
      Paint()..color = AppThemeColors.diamondBlue,
    );
    canvas.drawCircle(
      Offset(c.dx + size.width * 0.1, c.dy - size.height * 0.04),
      size.width * 0.05,
      Paint()..color = AppThemeColors.diamondBlue,
    );
    canvas.drawCircle(c, size.width * 0.4, Paint()..color = glow.withValues(alpha: 0.22)..maskFilter = const MaskFilter.blur(BlurStyle.normal, 22));
  }
}

class _CarPainter extends _PremiumPainter {
  _CarPainter({required super.glow});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final body = RRect.fromRectAndRadius(
      Rect.fromLTWH(w * 0.12, h * 0.42, w * 0.76, h * 0.28),
      Radius.circular(h * 0.08),
    );
    canvas.drawRRect(
      body,
      Paint()
        ..shader = LinearGradient(
          colors: [AppThemeColors.accentPink, AppThemeColors.accentPurple],
        ).createShader(body.outerRect),
    );
    canvas.drawCircle(Offset(w * 0.28, h * 0.72), w * 0.1, Paint()..color = const Color(0xFF1A1A24));
    canvas.drawCircle(Offset(w * 0.72, h * 0.72), w * 0.1, Paint()..color = const Color(0xFF1A1A24));
    canvas.drawCircle(Offset(w * 0.5, h * 0.5), w * 0.45, Paint()..color = glow.withValues(alpha: 0.2)..maskFilter = const MaskFilter.blur(BlurStyle.normal, 20));
  }
}

class _DiamondPainter extends _PremiumPainter {
  _DiamondPainter({required super.glow});

  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2);
    final path = Path()
      ..moveTo(c.dx, size.height * 0.14)
      ..lineTo(size.width * 0.78, size.height * 0.42)
      ..lineTo(c.dx, size.height * 0.86)
      ..lineTo(size.width * 0.22, size.height * 0.42)
      ..close();
    canvas.drawPath(
      path,
      Paint()
        ..shader = LinearGradient(
          colors: [Colors.white, AppThemeColors.diamondBlue, AppThemeColors.accentPurple],
        ).createShader(Rect.fromLTWH(0, 0, size.width, size.height)),
    );
    canvas.drawPath(path, Paint()..color = Colors.white.withValues(alpha: 0.35)..style = PaintingStyle.stroke..strokeWidth = 2);
    canvas.drawCircle(c, size.width * 0.42, Paint()..color = glow.withValues(alpha: 0.25)..maskFilter = const MaskFilter.blur(BlurStyle.normal, 26));
  }
}

class _HeartPainter extends _PremiumPainter {
  _HeartPainter({required super.glow});

  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height * 0.55);
    final paint = Paint()
      ..shader = RadialGradient(
        colors: [AppThemeColors.accentPink, const Color(0xFFE91E63)],
      ).createShader(Rect.fromCircle(center: c, radius: size.width * 0.4));
    final path = Path()
      ..moveTo(c.dx, size.height * 0.78)
      ..cubicTo(size.width * 0.1, size.height * 0.45, size.width * 0.1, size.height * 0.18, c.dx, size.height * 0.32)
      ..cubicTo(size.width * 0.9, size.height * 0.18, size.width * 0.9, size.height * 0.45, c.dx, size.height * 0.78)
      ..close();
    canvas.drawPath(path, paint);
    canvas.drawCircle(c, size.width * 0.38, Paint()..color = glow.withValues(alpha: 0.2)..maskFilter = const MaskFilter.blur(BlurStyle.normal, 20));
  }
}

class _CrownPainter extends _PremiumPainter {
  _CrownPainter({required super.glow});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final base = Path()
      ..moveTo(w * 0.18, size.height * 0.62)
      ..lineTo(w * 0.82, size.height * 0.62)
      ..lineTo(w * 0.78, size.height * 0.78)
      ..lineTo(w * 0.22, size.height * 0.78)
      ..close();
    final peaks = Path()
      ..moveTo(w * 0.18, size.height * 0.62)
      ..lineTo(w * 0.28, size.height * 0.28)
      ..lineTo(w * 0.42, size.height * 0.5)
      ..lineTo(w * 0.5, size.height * 0.22)
      ..lineTo(w * 0.58, size.height * 0.5)
      ..lineTo(w * 0.72, size.height * 0.28)
      ..lineTo(w * 0.82, size.height * 0.62)
      ..close();
    final gold = Paint()
      ..shader = LinearGradient(colors: [AppThemeColors.coinGold, const Color(0xFFFFE082)]).createShader(Rect.fromLTWH(0, 0, w, size.height));
    canvas.drawPath(peaks, gold);
    canvas.drawPath(base, gold);
    canvas.drawCircle(Offset(w * 0.5, size.height * 0.48), w * 0.4, Paint()..color = glow.withValues(alpha: 0.22)..maskFilter = const MaskFilter.blur(BlurStyle.normal, 22));
  }
}

class _YachtPainter extends _PremiumPainter {
  _YachtPainter({required super.glow});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    canvas.drawPath(
      Path()
        ..moveTo(w * 0.15, h * 0.62)
        ..lineTo(w * 0.85, h * 0.62)
        ..lineTo(w * 0.72, h * 0.78)
        ..lineTo(w * 0.28, h * 0.78)
        ..close(),
      Paint()..color = Colors.white.withValues(alpha: 0.95),
    );
    canvas.drawRect(
      Rect.fromLTWH(w * 0.42, h * 0.28, w * 0.08, h * 0.36),
      Paint()..color = AppThemeColors.accentPurple,
    );
    canvas.drawPath(
      Path()
        ..moveTo(w * 0.46, h * 0.28)
        ..lineTo(w * 0.72, h * 0.42)
        ..lineTo(w * 0.46, h * 0.42)
        ..close(),
      Paint()..color = AppThemeColors.accentPink.withValues(alpha: 0.9),
    );
    canvas.drawCircle(Offset(w * 0.5, h * 0.5), w * 0.42, Paint()..color = glow.withValues(alpha: 0.2)..maskFilter = const MaskFilter.blur(BlurStyle.normal, 24));
  }
}

class _GenericGiftPainter extends _PremiumPainter {
  _GenericGiftPainter({required this.emoji, required super.glow});

  final String emoji;

  @override
  void paint(Canvas canvas, Size size) {
    final tp = TextPainter(
      text: TextSpan(text: emoji, style: TextStyle(fontSize: size.width * 0.5)),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, Offset((size.width - tp.width) / 2, (size.height - tp.height) / 2));
  }
}
