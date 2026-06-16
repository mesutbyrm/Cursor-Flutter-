import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../core/ui/premium_2026/premium_2026_tokens.dart';
import '../../core/theme/pf_theme.dart';

/// Premium cam efektli kart.
class PfGlassCard extends StatelessWidget {
  const PfGlassCard({
    super.key,
    required this.child,
    this.onTap,
    this.padding = const EdgeInsets.all(18),
    this.margin,
    this.gradient,
  });

  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;
  final Gradient? gradient;

  @override
  Widget build(BuildContext context) {
    final t = context.p26;
    final content = ClipRRect(
      borderRadius: BorderRadius.circular(t.radiusSheet),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: gradient ??
                LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    PfTheme.card.withValues(alpha: 0.92),
                    PfTheme.surfaceElevated.withValues(alpha: 0.88),
                  ],
                ),
            borderRadius: BorderRadius.circular(t.radiusSheet),
            border: Border.all(color: t.glassBorder.withValues(alpha: 0.35)),
            boxShadow: t.shadowAmbient,
          ),
          child: Padding(padding: padding, child: child),
        ),
      ),
    );

    final wrapped = onTap != null
        ? Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(t.radiusSheet),
              child: content,
            ),
          )
        : content;

    return Padding(
      padding: margin ?? EdgeInsets.zero,
      child: wrapped.animate().fadeIn(duration: 280.ms).slideY(
            begin: 0.04,
            curve: Curves.easeOutCubic,
          ),
    );
  }
}
