import 'package:flutter/material.dart';
import 'package:canlifal_social/core/theme/app_theme_colors.dart';
import 'package:canlifal_social/core/theme/app_theme_extensions.dart';
import 'package:flutter_animate/flutter_animate.dart';


enum NeonButtonSize { sm, md, lg }

/// Gradient CTA — canlı yayın / jeton / premium aksiyonlar.
class NeonButton extends StatelessWidget {
  const NeonButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.size = NeonButtonSize.md,
    this.expand = false,
    this.pulse = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final NeonButtonSize size;
  final bool expand;
  final bool pulse;

  @override
  Widget build(BuildContext context) {
    final heights = switch (size) {
      NeonButtonSize.sm => 40.0,
      NeonButtonSize.md => 48.0,
      NeonButtonSize.lg => 56.0,
    };
    final fontSize = switch (size) {
      NeonButtonSize.sm => 13.0,
      NeonButtonSize.md => 15.0,
      NeonButtonSize.lg => 17.0,
    };

    Widget button = Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(14),
        child: Ink(
          height: heights,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            gradient: context.colors.brandGradient,
            boxShadow: onPressed != null
                ? AppThemeColors.glowShadow(AppThemeColors.accentPink, blur: 16)
                : null,
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (icon != null) ...[
                  Icon(icon, color: Colors.white, size: fontSize + 4),
                  const SizedBox(width: 8),
                ],
                Text(
                  label,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: fontSize,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    if (expand) {
      button = SizedBox(width: double.infinity, child: button);
    }

    if (pulse && onPressed != null) {
      button = button
          .animate(onPlay: (c) => c.repeat(reverse: true))
          .scale(
            begin: const Offset(1, 1),
            end: const Offset(1.02, 1.02),
            duration: 1200.ms,
          );
    }

    return button;
  }
}
