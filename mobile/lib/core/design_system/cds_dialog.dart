import 'package:flutter/material.dart';

import '../theme/app_spacing.dart';
import '../theme/app_theme_extensions.dart';
import 'cds_button.dart';

/// CDS onay diyalogu.
abstract final class CdsDialog {
  static Future<bool?> confirm(
    BuildContext context, {
    required String title,
    required String message,
    String confirmLabel = 'Tamam',
    String cancelLabel = 'İptal',
    CdsButtonVariant confirmVariant = CdsButtonVariant.primary,
  }) {
    return showDialog<bool>(
      context: context,
      barrierColor: context.colors.barrier,
      builder: (ctx) => AlertDialog(
        backgroundColor: context.colors.dialogBackground,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
        ),
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(cancelLabel),
          ),
          CdsButton(
            label: confirmLabel,
            expand: false,
            variant: confirmVariant,
            onPressed: () => Navigator.of(ctx).pop(true),
          ),
        ],
      ),
    );
  }
}
