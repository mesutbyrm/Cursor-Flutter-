import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_theme_colors.dart';
import '../theme/app_theme_extensions.dart';

/// Ana sayfada geri tuşu — doğrudan kapanma yerine çıkış onayı.
Future<ExitDialogAction?> showExitConfirmDialog(BuildContext context) {
  return showDialog<ExitDialogAction>(
    context: context,
    builder: (ctx) {
      final colors = ctx.colors;
      return AlertDialog(
        backgroundColor: colors.dialogBackground,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Uygulamadan çıkmak istiyor musunuz?',
          style: TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 18,
            color: colors.onSurface,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, ExitDialogAction.stay),
            child: const Text('Hayır'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, ExitDialogAction.exitApp),
            style: FilledButton.styleFrom(
              backgroundColor: AppThemeColors.liveRed,
            ),
            child: const Text('Evet'),
          ),
        ],
      );
    },
  );
}

enum ExitDialogAction { stay, exitApp }

/// Ana sayfada geri: "Uygulamadan çıkmak istiyor musunuz?" → Evet ise kapat.
Future<void> handleShellBackPress(BuildContext context) async {
  final action = await showExitConfirmDialog(context);
  if (action == ExitDialogAction.exitApp) {
    await SystemNavigator.pop();
  }
}
