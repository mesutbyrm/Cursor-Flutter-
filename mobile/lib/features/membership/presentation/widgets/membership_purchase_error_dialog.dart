import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../domain/membership_purchase_error.dart';

/// Üyelik satın alma hatasının teknik ayrıntısı (istek/yanıt) — kopyalanabilir.
Future<void> showMembershipPurchaseErrorDetails(
  BuildContext context,
  MembershipPurchaseException error,
) {
  final report = error.technicalReport;
  return showDialog<void>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Hata ayrıntısı'),
      content: SizedBox(
        width: double.maxFinite,
        child: SingleChildScrollView(
          child: SelectableText(
            report,
            style: const TextStyle(fontFamily: 'monospace', fontSize: 11.5),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () async {
            await Clipboard.setData(ClipboardData(text: report));
            if (ctx.mounted) {
              ScaffoldMessenger.of(ctx).showSnackBar(
                const SnackBar(content: Text('Ayrıntı kopyalandı')),
              );
            }
          },
          child: const Text('Kopyala'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(ctx),
          child: const Text('Kapat'),
        ),
      ],
    ),
  );
}
