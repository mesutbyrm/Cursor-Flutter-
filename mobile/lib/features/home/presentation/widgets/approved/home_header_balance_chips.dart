import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/economy/presentation/widgets/branded_dual_balance_chips.dart';
import '../../../../auth/presentation/providers/auth_providers.dart';
import '../../../../profile/presentation/providers/profile_providers.dart';
import '../../../../../core/bootstrap/shell_header_badges_provider.dart';

/// Ana sayfa üst bar — kompakt markalı jeton + CFC.
class HomeHeaderBalanceChips extends ConsumerWidget {
  const HomeHeaderBalanceChips({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final badgesReady = ref.watch(shellHeaderBadgesEnabledProvider);
    final wallet = badgesReady
        ? ref.watch(walletBalancesProvider.select((w) => w.valueOrNull))
        : null;
    final authJeton = ref.watch(
      authControllerProvider.select((a) => a.valueOrNull?.coinBalance),
    );
    final jeton = wallet?.jeton ?? authJeton ?? 0;
    final cfc = wallet?.cfc ?? 0;

    return BrandedDualBalanceChips(
      jeton: jeton,
      cfc: cfc,
      compact: true,
    );
  }
}
