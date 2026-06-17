import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Falcı kabul etmediğinde danışan ve falcıya gösterilen iade bildirimi.
Future<void> showLiveFortuneUnavailableDialog(
  BuildContext context, {
  String? tellerName,
}) {
  return showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (ctx) => AlertDialog(
      backgroundColor: const Color(0xFF1A0F2E),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: const Text(
        'Falcı müsait değil',
        textAlign: TextAlign.center,
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w900,
          fontSize: 18,
        ),
      ),
      content: Text(
        tellerName != null && tellerName.trim().isNotEmpty
            ? '$tellerName şu an müsait değil. Lütfen daha sonra tekrar deneyiniz.\n\nJetonlarınız iade edildi.'
            : 'Canlı falcı şu an müsait değil. Lütfen daha sonra tekrar deneyiniz.\n\nJetonlarınız iade edildi.',
        textAlign: TextAlign.center,
        style: const TextStyle(color: Colors.white70, height: 1.45),
      ),
      actionsAlignment: MainAxisAlignment.center,
      actions: [
        FilledButton(
          onPressed: () {
            Navigator.pop(ctx);
            final router = GoRouter.of(ctx);
            while (router.canPop()) {
              router.pop();
            }
            router.go('/');
          },
          style: FilledButton.styleFrom(
            backgroundColor: const Color(0xFF7C4DFF),
            minimumSize: const Size(160, 44),
          ),
          child: const Text('Ana Sayfaya Dön'),
        ),
      ],
    ),
  );
}
