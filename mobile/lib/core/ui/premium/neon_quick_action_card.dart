import 'dart:ui';

import 'package:flutter/material.dart';

import '../../theme/app_spacing.dart';

/// Ana sayfa hızlı işlem — cam efekt, neon glow, basınca 0.96 ölçek.
class NeonQuickActionCard extends StatefulWidget {
  const NeonQuickActionCard({
    super.key,
    required this.label,
    required this.gradient,
    required this.glowColor,
    required this.icon,
    required this.onTap,
    this.size = AppSpacing.quickActionSize + 4,
  });

  final String label;
  final List<Color> gradient;
  final Color glowColor;
  final Widget icon;
  final VoidCallback onTap;
  final double size;

  @override
  State<NeonQuickActionCard> createState() => _NeonQuickActionCardState();
}

class _NeonQuickActionCardState extends State<NeonQuickActionCard> {
  var _pressed = false;

  @override
  Widget build(BuildContext context) {
    final scale = _pressed ? 0.96 : 1.0;
    final glowBoost = _pressed ? 0.72 : 0.5;

    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: scale,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
        child: SizedBox(
          width: widget.size,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 120),
                width: widget.size,
                height: widget.size,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(22),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: widget.gradient,
                  ),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.18),
                    width: 1.2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: widget.glowColor.withValues(alpha: glowBoost),
                      blurRadius: _pressed ? 22 : 16,
                      spreadRadius: _pressed ? 2 : 0,
                      offset: const Offset(0, 6),
                    ),
                    BoxShadow(
                      color: widget.gradient.last.withValues(alpha: 0.35),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(22),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.white.withValues(alpha: 0.14),
                            Colors.transparent,
                          ],
                        ),
                      ),
                      child: Center(child: widget.icon),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                widget.label,
                textAlign: TextAlign.center,
                maxLines: 2,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  height: 1.2,
                  letterSpacing: 0.1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Neon glow ikon sarmalayıcı.
class NeonQuickActionIcon extends StatelessWidget {
  const NeonQuickActionIcon({
    super.key,
    required this.child,
    required this.glowColor,
    this.size = 34,
  });

  final Widget child;
  final Color glowColor;
  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: DecoratedBox(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: glowColor.withValues(alpha: 0.65),
              blurRadius: 18,
              spreadRadius: 1,
            ),
          ],
        ),
        child: child,
      ),
    );
  }
}
