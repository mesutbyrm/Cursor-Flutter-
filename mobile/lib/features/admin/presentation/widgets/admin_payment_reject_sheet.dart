import 'package:flutter/material.dart';

/// Ödeme red şablonları — admin hub + komuta merkezi.
abstract final class AdminPaymentRejectTemplates {
  static const items = [
    'Dekont tutarı eşleşmiyor',
    'Dekont okunamıyor / eksik',
    'Yanlış IBAN veya hesap',
    'Tekrarlayan talep',
    'Şüpheli işlem — destek ile iletişim',
  ];
}

/// Red sebebi — şablon chip + serbest metin.
Future<String?> showAdminPaymentRejectSheet(BuildContext context) async {
  final ctrl = TextEditingController();
  final result = await showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    builder: (ctx) => Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        20,
        20,
        20 + MediaQuery.viewInsetsOf(ctx).bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Ödemeyi reddet',
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final t in AdminPaymentRejectTemplates.items)
                ActionChip(
                  label: Text(t, style: const TextStyle(fontSize: 11)),
                  onPressed: () {
                    ctrl.text = t;
                  },
                ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: ctrl,
            maxLines: 3,
            decoration: const InputDecoration(
              labelText: 'Red sebebi (kullanıcıya bildirilir)',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Vazgeç'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: FilledButton(
                  onPressed: () {
                    final text = ctrl.text.trim();
                    if (text.isEmpty) return;
                    Navigator.pop(ctx, text);
                  },
                  child: const Text('Reddet'),
                ),
              ),
            ],
          ),
        ],
      ),
    ),
  );
  ctrl.dispose();
  return result;
}
