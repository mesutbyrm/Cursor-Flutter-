import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Danışan veya falcı oturumu / bekleme ekranını kapatmak istediğinde.
Future<bool> showLiveFortuneCloseDialog(
  BuildContext context, {
  required String title,
  required String message,
  String confirmLabel = 'Kapat',
}) async {
  final ok = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (ctx) => AlertDialog(
      backgroundColor: const Color(0xFF1A0F2E),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Text(
        title,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w900,
          fontSize: 17,
        ),
      ),
      content: Text(
        message,
        style: const TextStyle(color: Colors.white70, height: 1.45),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: const Text('Vazgeç'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(ctx, true),
          style: FilledButton.styleFrom(
            backgroundColor: const Color(0xFFE53935),
          ),
          child: Text(confirmLabel),
        ),
      ],
    ),
  );
  return ok == true;
}

/// Tüm fal ekranlarını kapatıp ana sayfaya döner.
void liveFortuneExitToHome(BuildContext context) {
  final router = GoRouter.of(context);
  while (router.canPop()) {
    router.pop();
  }
  router.go('/');
}
