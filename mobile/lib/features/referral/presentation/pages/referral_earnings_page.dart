import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/economy/presentation/providers/economy_providers.dart';
import '../../../../core/economy/presentation/widgets/currency_amount_label.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/glow_panel.dart';
import '../providers/referral_providers.dart';

/// Kazançlarım — tüm tutarlar backend'den.
class ReferralEarningsPage extends ConsumerWidget {
  const ReferralEarningsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final earnings = ref.watch(referralEarningsProvider);
    final ledger = ref.watch(referralLedgerProvider);
    final economy = ref.watch(referralEconomyProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Kazançlarım'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(referralEarningsProvider);
          ref.invalidate(referralLedgerProvider);
          ref.invalidate(referralEconomyProvider);
          await Future.wait([
            ref.read(referralEarningsProvider.future),
            ref.read(referralLedgerProvider.future),
            ref.read(referralEconomyProvider.future),
          ]);
        },
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            earnings.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Text(ApiException.userMessage(e)),
              data: (s) => GlowPanel(
                borderRadius: 18,
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _EarningTile('Toplam kazanç', s.totalEarnings),
                    _EarningTile('Bu ay', s.monthEarnings),
                    _EarningTile('Bekleyen', s.pendingEarnings),
                    _EarningTile('Kullanılabilir', s.availableEarnings),
                    _EarningTile('İptal edilen', s.reversedEarnings),
                    _EarningTile('Limit (aylık)', s.monthlyLimit),
                    _EarningTile('Limit (ömür boyu)', s.lifetimeLimit),
                  ],
                ),
              ),
            ),
            economy.when(
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
              data: (snapshot) {
                if (snapshot == null) return const SizedBox.shrink();
                return Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: GlowPanel(
                    borderRadius: 18,
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Komisyon özeti (yeni API)',
                          style: TextStyle(fontWeight: FontWeight.w900),
                        ),
                        const SizedBox(height: 8),
                        _EconomyAmountTile(
                          label: 'Toplam komisyon',
                          amount: snapshot.totalCommission,
                          currencyKey: 'cfc',
                        ),
                        _EconomyAmountTile(
                          label: 'Bu ay',
                          amount: snapshot.monthCommission,
                          currencyKey: 'cfc',
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 20),
            const Text(
              'Son işlemler',
              style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
            ),
            const SizedBox(height: 10),
            ledger.when(
              loading: () => const Padding(
                padding: EdgeInsets.all(24),
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (e, _) => Text(ApiException.userMessage(e)),
              data: (items) {
                if (items.isEmpty) {
                  return Text(
                    'Henüz kayıt yok',
                    style: TextStyle(color: AppTheme.muted.withValues(alpha: 0.9)),
                  );
                }
                return Column(
                  children: items.take(30).map((e) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: GlowPanel(
                        borderRadius: 14,
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    e.sourceType,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  Text(
                                    e.createdAt.split('T').first,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: AppTheme.muted.withValues(alpha: 0.85),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  '+${e.referralCommission} Jeton',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w800,
                                    color: AppTheme.accent.withValues(alpha: 0.95),
                                  ),
                                ),
                                Text(
                                  e.status,
                                  style: const TextStyle(fontSize: 11),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _EarningTile extends StatelessWidget {
  const _EarningTile(this.label, this.amount);

  final String label;
  final int amount;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(child: Text(label)),
          Text(
            '$amount Jeton',
            style: const TextStyle(fontWeight: FontWeight.w800),
          ),
        ],
      ),
    );
  }
}

class _EconomyAmountTile extends ConsumerWidget {
  const _EconomyAmountTile({
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
      padding: const EdgeInsets.symmetric(vertical: 6),
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
