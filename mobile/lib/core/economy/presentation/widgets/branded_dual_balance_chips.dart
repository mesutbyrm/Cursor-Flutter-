import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../widgets/dual_balance_chips.dart';
import '../providers/economy_providers.dart';

/// Markalı jeton + CFC chip'leri — endpoint yoksa varsayılan etiketler.
class BrandedDualBalanceChips extends ConsumerWidget {
  const BrandedDualBalanceChips({
    super.key,
    required this.jeton,
    required this.cfc,
    this.compact = false,
    this.onJetonTap,
    this.onCfcTap,
    this.onTap,
  });

  final int jeton;
  final int cfc;
  final bool compact;
  final VoidCallback? onJetonTap;
  final VoidCallback? onCfcTap;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = Localizations.localeOf(context);
    final jetonLabel = economyCurrencyLabel(ref, key: 'jeton', locale: locale);
    final cfcLabel = economyCurrencyLabel(ref, key: 'cfc', locale: locale);
    return DualBalanceChips(
      jeton: jeton,
      cfc: cfc,
      compact: compact,
      jetonLabel: jetonLabel,
      cfcLabel: cfcLabel,
      onJetonTap: onJetonTap,
      onCfcTap: onCfcTap,
      onTap: onTap,
    );
  }
}
