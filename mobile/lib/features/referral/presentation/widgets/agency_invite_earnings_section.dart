import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/glow_panel.dart';
import '../../../../core/economy/presentation/providers/economy_providers.dart';
import '../../../../core/economy/presentation/widgets/currency_amount_label.dart';

/// Ajans davet komisyonu — yalnızca `/api/agency/invite-earnings` başarılıysa.
class AgencyInviteEarningsSection extends ConsumerWidget {
  const AgencyInviteEarningsSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final agency = ref.watch(agencyInviteEarningsProvider);
    return agency.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (snapshot) {
        if (snapshot == null || snapshot.agencyId == null) {
          return const SizedBox.shrink();
        }
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: GlowPanel(
            borderRadius: 18,
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  snapshot.agencyName?.trim().isNotEmpty == true
                      ? '${snapshot.agencyName} — Ajans kazancı'
                      : 'Ajans davet kazancı',
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 8),
                _AgencyStatRow(
                  label: 'Toplam',
                  amount: snapshot.totalEarnings,
                  currencyKey: 'cfc',
                ),
                _AgencyStatRow(
                  label: 'Bu ay',
                  amount: snapshot.monthEarnings,
                  currencyKey: 'cfc',
                ),
                if (snapshot.memberCount > 0)
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      '${snapshot.memberCount} üye',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppTheme.muted.withValues(alpha: 0.9),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _AgencyStatRow extends ConsumerWidget {
  const _AgencyStatRow({
    required this.label,
    required this.amount,
    required this.currencyKey,
  });

  final String label;
  final int amount;
  final String currencyKey;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(child: Text(label)),
          CurrencyAmountLabel(
            amount: amount,
            currencyKey: currencyKey,
            compact: true,
          ),
        ],
      ),
    );
  }
}
