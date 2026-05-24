import 'dart:ui';

import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import 'premium_2026_tokens.dart';
import 'premium_motion.dart';

/// iOS Liquid Glass + glassmorphism yüzey.
class LiquidGlass extends StatelessWidget {
  const LiquidGlass({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.margin,
    this.borderRadius,
    this.blur = 22,
    this.elevated = false,
    this.onTap,
    this.gradientBorder,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;
  final BorderRadius? borderRadius;
  final double blur;
  final bool elevated;
  final VoidCallback? onTap;
  final Gradient? gradientBorder;

  @override
  Widget build(BuildContext context) {
    final t = context.p26;
    final radius = borderRadius ?? BorderRadius.circular(t.radiusLiquid);
    final fill = elevated ? t.glassFillElevated : t.glassFill;
    final border = gradientBorder ??
        LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            t.glassBorder,
            t.glassBorder.withValues(alpha: 0.15),
            AppColors.accentPurple.withValues(alpha: 0.35),
          ],
        );

    Widget inner = ClipRRect(
      borderRadius: radius,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: radius,
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                fill,
                fill.withValues(alpha: fill.a * 0.65),
              ],
            ),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.08),
              width: 0.5,
            ),
            boxShadow: elevated ? t.shadowFloating : t.shadowAmbient,
          ),
          child: Stack(
            children: [
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                height: 1,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        t.glassHighlight,
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
              Padding(padding: padding, child: child),
            ],
          ),
        ),
      ),
    );

    inner = Container(
      decoration: BoxDecoration(
        borderRadius: radius,
        gradient: border,
      ),
      padding: const EdgeInsets.all(1),
      child: inner,
    );

    if (margin != null) {
      inner = Padding(padding: margin!, child: inner);
    }

    if (onTap == null) return inner;

    return PressableScale(
      onTap: onTap!,
      child: inner,
    );
  }
}

/// Animasyonlu cam kart — durum değişimlerinde yumuşak geçiş.
class LiquidGlassCard extends StatefulWidget {
  const LiquidGlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.onTap,
    this.elevated = false,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final bool elevated;

  @override
  State<LiquidGlassCard> createState() => _LiquidGlassCardState();
}

class _LiquidGlassCardState extends State<LiquidGlassCard> {
  var _pressed = false;

  @override
  Widget build(BuildContext context) {
    return AnimatedScale(
      scale: _pressed ? 0.98 : 1,
      duration: PremiumMotion.fast,
      curve: PremiumMotion.spring,
      child: AnimatedContainer(
        duration: PremiumMotion.medium,
        curve: PremiumMotion.easeOut,
        child: LiquidGlass(
          padding: widget.padding,
          elevated: widget.elevated,
          onTap: widget.onTap == null
              ? null
              : () {
                  setState(() => _pressed = true);
                  widget.onTap!();
                  Future.delayed(PremiumMotion.fast, () {
                    if (mounted) setState(() => _pressed = false);
                  });
                },
          child: widget.child,
        ),
      ),
    );
  }
}

/// Mikro etkileşim — basma ölçeği (TikTok tarzı).
class PressableScale extends StatefulWidget {
  const PressableScale({
    super.key,
    required this.child,
    required this.onTap,
    this.scaleDown = 0.94,
  });

  final Widget child;
  final VoidCallback onTap;
  final double scaleDown;

  @override
  State<PressableScale> createState() => _PressableScaleState();
}

class _PressableScaleState extends State<PressableScale> {
  var _down = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _down = true),
      onTapUp: (_) => setState(() => _down = false),
      onTapCancel: () => setState(() => _down = false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _down ? widget.scaleDown : 1,
        duration: PremiumMotion.fast,
        curve: PremiumMotion.spring,
        child: widget.child,
      ),
    );
  }
}
