import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/datasources/agency_wallet_datasource.dart';
import '../../../../core/network/dio_provider.dart';

class AgencyJetonTransferSheet {
  AgencyJetonTransferSheet._();

  static Future<void> show(
    BuildContext context, {
    required WidgetRef ref,
    required String memberUserId,
    required String memberLabel,
    required double agencyBalance,
    required VoidCallback onSuccess,
  }) async {
    final amountCtrl = TextEditingController();
    final reasonCtrl = TextEditingController();
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
        return Padding(
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
              Text(
                'Jeton gönder — $memberLabel',
                style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
              ),
              const SizedBox(height: 8),
              Text(
                'Ajans bakiyesi: ${agencyBalance.toStringAsFixed(0)} jeton',
                style: const TextStyle(fontSize: 12, color: Colors.white54),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: amountCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Gönderilecek jeton',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: reasonCtrl,
                decoration: const InputDecoration(
                  labelText: 'Not (isteğe bağlı)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () async {
                  final amount = int.tryParse(amountCtrl.text.trim()) ?? 0;
                  if (amount <= 0) return;
                  final ds = AgencyWalletDataSource(ref.read(dioProvider));
                  final res = await ds.transfer(
                    targetUserId: memberUserId,
                    amount: amount,
                    reason: reasonCtrl.text,
                  );
                  final ok = res.ok;
                  if (!ctx.mounted) return;
                  Navigator.pop(ctx);
                  // Sunucunun mesajı aynen: ör. "Ajans bakiyesi yetersiz: 1 jeton eksik".
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(res.message)),
                  );
                  if (ok) onSuccess();
                },
                child: const Text('Gönder'),
              ),
            ],
          ),
        );
      },
    );
  }
}
