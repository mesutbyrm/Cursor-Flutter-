import 'package:canlifal_social/core/performance/effects_perf.dart';
import 'package:canlifal_social/core/widgets/themed_glass_card.dart';
import 'package:flutter/material.dart';

import '../../../core/ui/premium_2026/premium_2026_tokens.dart';
import '../../core/theme/pf_theme.dart';

/// Premium cam efektli kart — merkezi glass + RepaintBoundary.
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
    final card = EffectsPerf.repaint(
      ThemedGlassCard(
        padding: padding,
        margin: margin,
        blur: 16,
        borderRadius: BorderRadius.circular(t.radiusSheet),
        onTap: onTap,
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
          child: child,
        ),
      ),
    );

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOutCubic,
      builder: (context, opacity, child) {
        return Opacity(opacity: opacity, child: child);
      },
      child: card,
    );
  }
}
