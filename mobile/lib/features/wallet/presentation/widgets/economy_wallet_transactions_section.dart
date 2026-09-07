import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/economy/presentation/providers/economy_providers.dart';
import '../../../../core/economy/presentation/widgets/currency_amount_label.dart';
import '../../../../core/theme/app_theme_extensions.dart';
import '../../domain/economy_wallet_snapshot.dart';

/// Birleşik cüzdan işlem geçmişi — yalnızca `/api/user/wallet` başarılıysa görünür.
class EconomyWalletTransactionsSection extends ConsumerWidget {
  const EconomyWalletTransactionsSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unified = ref.watch(unifiedEconomyWalletProvider);
    return unified.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (snapshot) {
        if (snapshot.transactions.isEmpty) return const SizedBox.shrink();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Son işlemler',
              style: TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 16,
                color: context.colors.onSurface,
              ),
            ),
            const SizedBox(height: 10),
            ...snapshot.transactions.take(8).map(
                  (tx) => _TransactionTile(transaction: tx),
                ),
          ],
        );
      },
    );
  }
}

class _TransactionTile extends ConsumerWidget {
  const _TransactionTile({required this.transaction});

  final EconomyWalletTransaction transaction;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final signed = transaction.amount >= 0
        ? '+${transaction.amount}'
        : '${transaction.amount}';
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white12),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  transaction.description?.trim().isNotEmpty == true
                      ? transaction.description!.trim()
                      : transaction.type,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                if (transaction.createdAt != null)
                  Text(
                    transaction.createdAt!.split('T').first,
                    style: TextStyle(
                      fontSize: 11,
                      color: context.colors.onSurfaceMuted,
                    ),
                  ),
              ],
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                signed,
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  color: transaction.amount >= 0
                      ? const Color(0xFF81C784)
                      : const Color(0xFFFF8A80),
                ),
              ),
              const SizedBox(width: 6),
              CurrencyAmountLabel(
                amount: transaction.balanceAfter.abs(),
                currencyKey: transaction.currency,
                compact: true,
                showName: false,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
