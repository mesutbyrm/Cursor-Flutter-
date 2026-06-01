import 'dart:ui';

import 'package:flutter/material.dart';

import '../../performance/list_perf.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';

class DiscoverGlassCard extends StatelessWidget {
  const DiscoverGlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.onTap,
    this.borderColor,
    this.blur = 16,
    this.useBlur = true,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final Color? borderColor;
  final double blur;
  final bool useBlur;

  @override
  Widget build(BuildContext context) {
    final border = borderColor ?? AppColors.accentPurple.withValues(alpha: 0.28);
    final radius = BorderRadius.circular(AppSpacing.radiusLg);

    Widget content = Container(
      padding: padding,
      decoration: BoxDecoration(
        borderRadius: radius,
        color: const Color(0xFF16162A).withValues(alpha: useBlur ? 0.55 : 0.88),
        border: Border.all(color: border, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.35),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: child,
    );

    if (useBlur) {
      content = ClipRRect(
        borderRadius: radius,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
          child: content,
        ),
      );
    }

    content = ListPerf.repaint(content);

    if (onTap == null) return content;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: radius,
        child: content,
      ),
    );
  }
}
