import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'ultra_fortune_liquid_surface.dart';
import 'ultra_fortune_tokens.dart';

/// Liquid Glass CTA — dokunuşta sıvı yayılım animasyonu.
class UltraFortuneRippleButton extends StatefulWidget {
  const UltraFortuneRippleButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.compact = false,
  });

  final String label;
  final VoidCallback onPressed;
  final IconData? icon;
  final bool compact;

  @override
  State<UltraFortuneRippleButton> createState() => _UltraFortuneRippleButtonState();
}

class _UltraFortuneRippleButtonState extends State<UltraFortuneRippleButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ripple;
  Offset? _tapOrigin;

  @override
  void initState() {
    super.initState();
    _ripple = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _ripple.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _ripple.reset();
        _tapOrigin = null;
      }
    });
  }

  @override
  void dispose() {
    _ripple.dispose();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails details) {
    setState(() => _tapOrigin = details.localPosition);
    _ripple.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    final compact = widget.compact;

    return GestureDetector(
      onTapDown: _handleTapDown,
      onTap: widget.onPressed,
      child: AnimatedBuilder(
        animation: _ripple,
        builder: (_, __) {
          return UltraFortuneLiquidSurface(
            goldAccent: true,
            borderRadius: BorderRadius.circular(compact ? 20 : 28),
            padding: EdgeInsets.symmetric(
              horizontal: compact ? 14 : 22,
              vertical: compact ? 10 : 14,
            ),
            child: Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.center,
              children: [
                if (_tapOrigin != null)
                  Positioned.fill(
                    child: CustomPaint(
                      painter: _LiquidRipplePainter(
                        origin: _tapOrigin!,
                        progress: Curves.easeOut.transform(_ripple.value),
                      ),
                    ),
                  ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (widget.icon != null) ...[
                      Icon(widget.icon, color: Colors.white, size: compact ? 14 : 18),
                      SizedBox(width: compact ? 6 : 10),
                    ] else ...[
                      const Text('✨', style: TextStyle(fontSize: 16)),
                      const SizedBox(width: 8),
                    ],
                    Text(
                      widget.label,
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: compact ? 11 : 13,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Icon(
                      Icons.chevron_right_rounded,
                      color: UltraFortuneTokens.metallicGold.withValues(alpha: 0.95),
                      size: compact ? 16 : 20,
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _LiquidRipplePainter extends CustomPainter {
  _LiquidRipplePainter({required this.origin, required this.progress});

  final Offset origin;
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0) return;
    final maxR = math.sqrt(size.width * size.width + size.height * size.height);
    final r = maxR * progress;
    final paint = Paint()
      ..shader = RadialGradient(
        colors: [
          UltraFortuneTokens.softLilac.withValues(alpha: 0.35 * (1 - progress)),
          UltraFortuneTokens.metallicGold.withValues(alpha: 0.2 * (1 - progress)),
          Colors.transparent,
        ],
      ).createShader(Rect.fromCircle(center: origin, radius: r));
    canvas.drawCircle(origin, r, paint);
  }

  @override
  bool shouldRepaint(covariant _LiquidRipplePainter old) =>
      old.progress != progress || old.origin != origin;
}
