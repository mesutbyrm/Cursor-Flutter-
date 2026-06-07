import 'package:flutter/material.dart';

import '../../theme/app_spacing.dart';
import 'package:canlifal_social/core/theme/app_theme_extensions.dart';

/// Premium modal bottom sheet — tema uyumlu cam / yüzey.
Future<T?> showPremiumBottomSheet<T>({
  required BuildContext context,
  required Widget child,
  bool isScrollControlled = true,
}) {
  final c = context.colors;
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: isScrollControlled,
    backgroundColor: Colors.transparent,
    barrierColor: c.barrier,
    builder: (ctx) {
      final theme = Theme.of(ctx);
      return Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.viewInsetsOf(ctx).bottom,
        ),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: c.bottomSheetBackground,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(AppSpacing.radiusXl),
            ),
            border: Border(
              top: BorderSide(color: c.glassBorder),
            ),
            boxShadow: c.elevatedShadow,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 10),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: c.onSurfaceMuted.withValues(alpha: 0.45),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 8),
              Theme(
                data: theme,
                child: child,
              ),
            ],
          ),
        ),
      );
    },
  );
}
