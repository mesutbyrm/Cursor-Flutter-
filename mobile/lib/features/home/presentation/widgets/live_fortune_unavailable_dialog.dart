import 'package:flutter/material.dart';

/// Falcı kabul etmediğinde danışan ve falcıya gösterilen iade bildirimi.
Future<void> showLiveFortuneUnavailableDialog(BuildContext context) {
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
      content: const Text(
        'Canlı falcı şu an müsait değil. Lütfen daha sonra tekrar deneyiniz.\n\nJetonlarınız iade edildi.',
        textAlign: TextAlign.center,
        style: TextStyle(color: Colors.white70, height: 1.45),
      ),
      actionsAlignment: MainAxisAlignment.center,
      actions: [
        FilledButton(
          onPressed: () => Navigator.pop(ctx),
          style: FilledButton.styleFrom(
            backgroundColor: const Color(0xFF7C4DFF),
            minimumSize: const Size(160, 44),
          ),
          child: const Text('Tamam'),
        ),
      ],
    ),
  );
}
