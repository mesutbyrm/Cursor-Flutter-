import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/config/payment_defaults.dart';
import '../../../../core/content/currency_usage_info.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/discover_tab_layout.dart';
import '../../../feed/presentation/widgets/discover/discover_background.dart';
import '../../../wallet/domain/cfc_payment_request_entity.dart';
import '../providers/profile_providers.dart';
import '../widgets/cfc_balance_header.dart';
import '../widgets/cfc_native_checkout.dart';
import '../widgets/currency_usage_card.dart';

final cfcPaymentRequestsProvider =
    FutureProvider.autoDispose<List<CfcPaymentRequestEntity>>((ref) async {
  final all = await ref.watch(walletRepositoryProvider).myPaymentRequests();
  return all.where((r) => r.isCfc).toList();
});

/// CFC (CanlıFal Coin) yükleme — yalnızca CFC, jeton değil.
class CfcPurchasePage extends ConsumerWidget {
  const CfcPurchasePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final config = ref.watch(paymentConfigProvider);
    final wallet = ref.watch(walletBalancesProvider);
    final history = ref.watch(cfcPaymentRequestsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: DiscoverBackground(
        child: DiscoverSubPage(
          title: 'CFC Yükle',
          subtitle: 'CFC (CanlıFal Coin) · ${CurrencyUsageInfo.cfcPriceHint}',
          onRefresh: () async {
            ref.invalidate(paymentConfigProvider);
            ref.invalidate(walletBalancesProvider);
            ref.invalidate(cfcPaymentRequestsProvider);
          },
          body: config.when(
            loading: () => const Center(child: DiscoverAccentLoader()),
            error: (e, _) => ListView(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
              children: [
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Text(
                    'Ödeme ayarları çevrimdışı yüklendi: ${ApiException.userMessage(e)}',
                    style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
                  ),
                ),
                CfcNativeCheckout(
                  config: PaymentDefaults.config,
                  onSubmitted: () {
                    ref.invalidate(cfcPaymentRequestsProvider);
                    ref.invalidate(walletBalancesProvider);
                  },
                ),
              ],
            ),
            data: (cfg) => ListView(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
              children: [
                wallet.when(
                  data: (b) => CfcBalanceHeader(cfc: b.cfc),
                  loading: () => const SizedBox.shrink(),
                  error: (e, _) => Text(
                    ApiException.userMessage(e),
                    style: const TextStyle(color: AppColors.textMuted),
                  ),
                ),
                const SizedBox(height: 16),
                const CurrencyUsageCard.cfc(),
                const SizedBox(height: 20),
                CfcNativeCheckout(
                  config: cfg,
                  onSubmitted: () {
                    ref.invalidate(cfcPaymentRequestsProvider);
                    ref.invalidate(walletBalancesProvider);
                  },
                ),
                const SizedBox(height: 28),
                const Text(
                  'CFC yükleme talepleriniz',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                ),
                const SizedBox(height: 10),
                history.when(
                  loading: () => const Padding(
                    padding: EdgeInsets.all(16),
                    child: Center(child: CircularProgressIndicator()),
                  ),
                  error: (e, _) => Text(ApiException.userMessage(e)),
                  data: (rows) {
                    if (rows.isEmpty) {
                      return Text(
                        'Henüz CFC talebi yok.',
                        style: TextStyle(
                          color: AppColors.textMuted.withValues(alpha: 0.9),
                        ),
                      );
                    }
                    return Column(
                      children: rows.take(10).map((r) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: DiscoverGlassCard(
                            padding: const EdgeInsets.all(12),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        r.displayLine,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                      Text(
                                        _statusTr(r.status),
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: AppColors.diamondBlue
                                              .withValues(alpha: 0.9),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Icon(
                                  _statusIcon(r.status),
                                  color: _statusColor(r.status),
                                  size: 22,
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
        ),
      ),
    );
  }

  static String _statusTr(String s) => switch (s) {
        'approved' => 'Onaylandı — CFC yansıdı',
        'rejected' => 'Reddedildi',
        _ => 'Onay bekliyor',
      };

  static IconData _statusIcon(String s) => switch (s) {
        'approved' => Icons.check_circle_rounded,
        'rejected' => Icons.cancel_rounded,
        _ => Icons.schedule_rounded,
      };

  static Color _statusColor(String s) => switch (s) {
        'approved' => AppColors.accentCyan,
        'rejected' => AppColors.liveRed,
        _ => AppColors.diamondBlue,
      };
}
