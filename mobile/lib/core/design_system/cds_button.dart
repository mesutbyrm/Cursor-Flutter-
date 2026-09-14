import 'package:flutter/material.dart';

import 'cds_colors.dart';
import 'cds_spacing.dart';

enum CdsButtonVariant { primary, secondary, ghost, danger }

/// CDS buton — tema [FilledButton] / outline ile hizalı.
class CdsButton extends StatelessWidget {
  const CdsButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.variant = CdsButtonVariant.primary,
    this.icon,
    this.loading = false,
    this.expand = true,
  });

  final String label;
  final VoidCallback? onPressed;
  final CdsButtonVariant variant;
  final IconData? icon;
  final bool loading;
  final bool expand;

  @override
  Widget build(BuildContext context) {
    final child = loading
        ? const SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(strokeWidth: 2),
          )
        : Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 20),
                const SizedBox(width: CdsSpacing.sm),
              ],
              Text(label),
            ],
          );

    final button = switch (variant) {
      CdsButtonVariant.primary => FilledButton(
          onPressed: loading ? null : onPressed,
          child: child,
        ),
      CdsButtonVariant.secondary => OutlinedButton(
          onPressed: loading ? null : onPressed,
          child: child,
        ),
      CdsButtonVariant.ghost => TextButton(
          onPressed: loading ? null : onPressed,
          child: child,
        ),
      CdsButtonVariant.danger => FilledButton(
          onPressed: loading ? null : onPressed,
          style: FilledButton.styleFrom(
            backgroundColor: CdsColors.error,
          ),
          child: child,
        ),
    };

    if (!expand) return button;
    return SizedBox(width: double.infinity, child: button);
  }
}
