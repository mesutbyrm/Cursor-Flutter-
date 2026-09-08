import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/economy/presentation/providers/economy_providers.dart';
import '../../../../../core/economy/presentation/widgets/currency_amount_label.dart';
import 'ultra_fortune_liquid_surface.dart';

/// Üst bar jeton / CFC chip'leri.
class UltraFortuneWalletChips extends ConsumerWidget {
  const UltraFortuneWalletChips({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final wallet = ref.watch(economyWalletProvider);

    return wallet.when(
      loading: () => const SizedBox.shrink(),
      error: (_, _) => const SizedBox.shrink(),
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
