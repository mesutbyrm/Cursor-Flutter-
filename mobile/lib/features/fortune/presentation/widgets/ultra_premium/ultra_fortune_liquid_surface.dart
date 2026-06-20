import 'dart:ui';

import 'package:flutter/material.dart';

import '../../../../../core/ui/platform_blur.dart';
import 'ultra_fortune_tokens.dart';

/// VisionOS / iOS 26 Liquid Glass — yüksek blur, specular highlight.
class UltraFortuneLiquidSurface extends StatelessWidget {
  const UltraFortuneLiquidSurface({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.margin,
    this.borderRadius,
    this.blur = UltraFortuneTokens.liquidBlur,
    this.onTap,
    this.elevated = false,
    this.goldAccent = false,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;
  final BorderRadius? borderRadius;
  final double blur;
  final VoidCallback? onTap;
  final bool elevated;
  final bool goldAccent;

  @override
  Widget build(BuildContext context) {
    final radius = borderRadius ?? BorderRadius.circular(UltraFortuneTokens.glassRadius);
    final blurEnabled = PlatformBlur.supportsBackdropBlur;
    final effectiveBlur = blurEnabled ? blur : 0.0;

    final fill = elevated
        ? const Color(0x1FFFFFFF)
        : UltraFortuneTokens.glassFill;

    Widget inner = DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: radius,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            fill,
            fill.withValues(alpha: fill.a * 0.55),
            const Color(0x087A2FFF),
          ],
        ),
        boxShadow: [
          ...UltraFortuneTokens.purpleGlow(blur: elevated ? 28 : 18),
          if (goldAccent) ...UltraFortuneTokens.goldGlow(),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            top: 0,
            left: 12,
            right: 12,
            height: 1.2,
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(1),
                gradient: LinearGradient(
                  colors: [
                    Colors.white.withValues(alpha: 0.45),
                    Colors.white.withValues(alpha: 0.08),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            height: radius.topLeft.y * 0.4,
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: radius,
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [
                    UltraFortuneTokens.electricPurple.withValues(alpha: 0.12),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          Padding(padding: padding, child: child),
        ],
      ),
    );

    if (effectiveBlur > 0) {
      inner = ClipRRect(
        borderRadius: radius,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: effectiveBlur, sigmaY: effectiveBlur),
          child: inner,
        ),
      );
    }

    inner = Container(
      decoration: BoxDecoration(
        borderRadius: radius,
        gradient: goldAccent
            ? const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0x66FFD67A),
                  Color(0x1AFFFFFF),
                  Color(0x4D7A2FFF),
                ],
              )
            : UltraFortuneTokens.glassBorderGradient,
      ),
      padding: const EdgeInsets.all(1.2),
      child: inner,
    );

    if (margin != null) {
      inner = Padding(padding: margin!, child: inner);
    }

    if (onTap == null) return inner;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: radius,
        splashColor: UltraFortuneTokens.softLilac.withValues(alpha: 0.2),
        highlightColor: UltraFortuneTokens.metallicGold.withValues(alpha: 0.08),
        child: inner,
      ),
    );
  }
}
