import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/economy/presentation/providers/economy_providers.dart';
import '../../../../../core/economy/presentation/widgets/currency_amount_label.dart';
import 'ultra_fortune_liquid_surface.dart';
import 'ultra_fortune_state_panel.dart';

/// Üst bar jeton / CFC chip'leri.
class UltraFortuneWalletChips extends ConsumerWidget {
  const UltraFortuneWalletChips({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final wallet = ref.watch(economyWalletProvider);

    return wallet.when(
      loading: () => const SizedBox(
        width: 72,
        height: 28,
        child: Center(
          child: SizedBox(
            width: 14,
            height: 14,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      ),
      error: (_, __) => UltraFortuneStatePanel(
        icon: Icons.account_balance_wallet_outlined,
        message: 'Cüzdan yüklenemedi',
        actionLabel: 'Yenile',
        onAction: () => ref.invalidate(economyWalletProvider),
        height: 56,
      ),
      data: (snap) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _Chip(
              child: CurrencyAmountLabel(
                amount: snap.cfc,
                currencyKey: 'cfc',
                compact: true,
                showName: false,
              ),
            ),
            const SizedBox(width: 4),
            _Chip(
              child: CurrencyAmountLabel(
                amount: snap.jeton,
                currencyKey: 'jeton',
                compact: true,
                showName: false,
              ),
            ),
          ],
        );
      },
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return UltraFortuneLiquidSurface(
      borderRadius: BorderRadius.circular(12),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      blur: 28,
      child: child,
    );
  }
}
