import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_exception.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/discover_tab_layout.dart';
import '../../../wallet/presentation/widgets/wallet_balance_header.dart';
import '../../../feed/presentation/widgets/discover/discover_background.dart';
import '../../../wallet/domain/cfc_payment_request_entity.dart';
import '../providers/profile_providers.dart';
import '../widgets/cfc_native_checkout.dart';

final cfcPaymentRequestsProvider =
    FutureProvider.autoDispose<List<CfcPaymentRequestEntity>>((ref) async {
  return ref.watch(walletRepositoryProvider).myPaymentRequests();
});

/// CFC (CanlıFal Coin) yükleme — site API ile aynı akış.
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
          subtitle: 'CanlıFal Coin · WhatsApp, Papara, Havale',
          onRefresh: () async {
            ref.invalidate(paymentConfigProvider);
            ref.invalidate(walletBalancesProvider);
            ref.invalidate(cfcPaymentRequestsProvider);
          },
          body: config.when(
            loading: () => const Center(child: DiscoverAccentLoader()),
            error: (e, _) => DiscoverEmptyState(
              icon: Icons.error_outline_rounded,
              message: ApiException.userMessage(e),
            ),
            data: (cfg) => ListView(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
              children: [
                wallet.when(
                  data: (b) => Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      WalletBalanceHeader(
                        jeton: b.jeton,
                        cfc: b.cfc,
                        membership: b.membership,
                        daysRemaining: b.membershipDaysRemaining,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Bakiye canlifal.com hesabınızdan · CFC: ${b.cfc}',
                        style: TextStyle(
                          fontSize: 11,
                          color: AppColors.textMuted.withValues(alpha: 0.9),
                        ),
                      ),
                    ],
                  ),
                  loading: () => const SizedBox.shrink(),
                  error: (e, _) => Text(
                    ApiException.userMessage(e),
                    style: const TextStyle(color: AppColors.textMuted),
                  ),
                ),
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
                  'Son talepleriniz',
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
                        'Henüz talep yok.',
                        style: TextStyle(color: AppColors.textMuted.withValues(alpha: 0.9)),
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
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        '${r.amount} CFC · ${_methodTr(r.method)}',
                                        style: const TextStyle(fontWeight: FontWeight.w700),
                                      ),
                                      Text(
                                        _statusTr(r.status),
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: AppColors.accentCyan.withValues(alpha: 0.9),
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

  static String _methodTr(String m) => switch (m) {
        'whatsapp' => 'WhatsApp',
        'papara' => 'Papara',
        'bank_transfer' => 'Havale/EFT',
        'havale' => 'Havale/EFT',
        _ => m,
      };

  static String _statusTr(String s) => switch (s) {
        'approved' => 'Onaylandı',
        'rejected' => 'Reddedildi',
        _ => 'Bekliyor',
      };

  static IconData _statusIcon(String s) => switch (s) {
        'approved' => Icons.check_circle_rounded,
        'rejected' => Icons.cancel_rounded,
        _ => Icons.schedule_rounded,
      };

  static Color _statusColor(String s) => switch (s) {
        'approved' => AppColors.accentCyan,
        'rejected' => AppColors.liveRed,
        _ => AppColors.coinGold,
      };
}
