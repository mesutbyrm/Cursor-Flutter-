import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_colors.dart';

/// Ana ekranda geri tuşu — doğrudan kapanma yerine çıkış onayı.
Future<ExitDialogAction?> showExitConfirmDialog(BuildContext context) {
  return showDialog<ExitDialogAction>(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: AppColors.bgPurpleGlow,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: const Text(
        'Çıkmak istiyor musunuz?',
        style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
      ),
      content: const Text(
        'Hesabınızdan çıkış yapabilir veya uygulamada kalmaya devam edebilirsiniz.',
        style: TextStyle(color: AppColors.textMuted, height: 1.35),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, ExitDialogAction.stay),
          child: const Text('İptal'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(ctx, ExitDialogAction.exitApp),
          child: const Text('Uygulamayı kapat'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(ctx, ExitDialogAction.logout),
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.liveRed,
          ),
          child: const Text('Çıkış yap'),
        ),
      ],
    ),
  );
}

enum ExitDialogAction { stay, logout, exitApp }

Future<void> handleShellBackPress(
  BuildContext context, {
  required Future<void> Function() onLogout,
}) async {
  final action = await showExitConfirmDialog(context);
  if (action == null || action == ExitDialogAction.stay) return;
  if (action == ExitDialogAction.logout) {
    await onLogout();
    return;
  }
  if (action == ExitDialogAction.exitApp) {
    await SystemNavigator.pop();
  }
}
