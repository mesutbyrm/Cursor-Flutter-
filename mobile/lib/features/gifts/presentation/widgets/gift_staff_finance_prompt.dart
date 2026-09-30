import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/gift_staff_finance_mode.dart';

/// Staff jeton modu kapatıldı — tüm hediyeler normal jeton akışıyla alıcıya düşer.
bool shouldAskGiftStaffFinanceMode(WidgetRef ref) => false;

/// `null` = kullanıcı iptal etti.
Future<GiftStaffFinanceMode?> showGiftStaffFinanceModeDialog(
  BuildContext context,
) async {
  return showDialog<GiftStaffFinanceMode>(
    context: context,
    barrierDismissible: true,
    builder: (ctx) {
      return AlertDialog(
        title: const Text('Jeton türü'),
        content: const Text(
          'Bu hediye için hangi jeton türünü kullanmak istiyorsunuz?\n\n'
          '• Staff jeton: Alıcıya jeton düşmez (tanıtım / moderasyon).\n'
          '• Gerçek jeton: Alıcı normal şekilde kredilenir.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('İptal'),
          ),
          FilledButton.tonal(
            onPressed: () => Navigator.pop(ctx, GiftStaffFinanceMode.staff),
            child: const Text('Staff jeton'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, GiftStaffFinanceMode.real),
            child: const Text('Gerçek jeton'),
          ),
        ],
      );
    },
  );
}

Future<GiftStaffFinanceMode?> resolveGiftStaffFinanceMode(
  BuildContext context,
  WidgetRef ref,
) async {
  if (!shouldAskGiftStaffFinanceMode(ref)) return null;
  return showGiftStaffFinanceModeDialog(context);
}
