import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:canlifal_social/core/theme/app_theme_colors.dart';

import '../../theme/app_spacing.dart';
import '../platform_blur.dart';

/// Glassmorphism yüzey — blur isteğe bağlı (performans için `blur: 0`).
class PremiumGlassSurface extends StatelessWidget {
  const PremiumGlassSurface({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(12),
    this.borderRadius,
    this.blur = 12,
    this.opacity = 0.35,
    this.borderColor,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final BorderRadius? borderRadius;
  final double blur;
  final double opacity;
  final Color? borderColor;

  @override
  Widget build(BuildContext context) {
    final radius = borderRadius ?? BorderRadius.circular(AppSpacing.radiusLg);
    final border = borderColor ?? AppThemeColors.accentPurple.withValues(alpha: 0.3);

    Widget content = Container(
      padding: padding,
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: opacity),
        borderRadius: radius,
        border: Border.all(color: border),
      ),
      child: child,
    );

    if (!PlatformBlur.supportsBackdropBlur || blur <= 0) {
      return ClipRRect(borderRadius: radius, child: content);
    }

    return ClipRRect(
      borderRadius: radius,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: content,
      ),
    );
  }
}
