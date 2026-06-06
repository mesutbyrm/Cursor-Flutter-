import 'package:flutter/material.dart';
import 'package:canlifal_social/core/theme/app_theme_colors.dart';
import 'package:canlifal_social/core/theme/app_theme_extensions.dart';
import 'package:canlifal_social/core/theme/app_theme_colors.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/config/payment_defaults.dart';
import '../../../../core/content/currency_usage_info.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/performance/list_perf.dart';
import '../../../../core/ui/pro_glass/pro_glass.dart';
import '../../../../core/widgets/discover_tab_layout.dart';
import '../../../feed/presentation/widgets/discover/discover_background.dart';
import '../../../wallet/domain/cfc_payment_request_entity.dart';
import '../providers/payment_requests_notifier.dart';
import '../providers/profile_providers.dart';
import '../widgets/cfc_balance_header.dart';
import '../widgets/cfc_native_checkout.dart';
import '../widgets/currency_usage_card.dart';

/// CFC (CanlıFal Coin) yükleme — yalnızca CFC, jeton değil.
class CfcPurchasePage extends ConsumerStatefulWidget {
  const CfcPurchasePage({super.key});

  @override
  ConsumerState<CfcPurchasePage> createState() => _CfcPurchasePageState();
}

class _CfcPurchasePageState extends ConsumerState<CfcPurchasePage> {
  final _scroll = ScrollController();

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scroll.removeListener(_onScroll);
    _scroll.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scroll.hasClients) return;
    if (_scroll.position.pixels >=
        _scroll.position.maxScrollExtent - ListPerf.preloadThresholdPx) {
      ref.read(paymentRequestsNotifierProvider.notifier).loadMore();
    }
  }

  Future<void> _refresh() async {
    ref.invalidate(paymentConfigProvider);
    ref.invalidate(walletBalancesProvider);
    await ref.read(paymentRequestsNotifierProvider.notifier).refresh();
  }

  @override
  Widget build(BuildContext context) {
    final config = ref.watch(paymentConfigProvider);
    final wallet = ref.watch(walletBalancesProvider);
    final history = ref.watch(paymentRequestsNotifierProvider);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: DiscoverBackground(
        child: DiscoverSubPage(
          title: 'CFC Yükle',
          subtitle: 'CFC (CanlıFal Coin) · ${CurrencyUsageInfo.cfcPriceHint}',
          onRefresh: _refresh,
          body: config.when(
            loading: () => const Center(child: DiscoverAccentLoader()),
            error: (e, _) => ListView(
              controller: _scroll,
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
              children: [
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Text(
                    'Ödeme ayarları çevrimdışı yüklendi: ${ApiException.userMessage(e)}',
                    style: TextStyle(color: context.colors.onSurfaceMuted, fontSize: 12),
                  ),
                ),
                CfcNativeCheckout(
                  config: PaymentDefaults.config,
                  onSubmitted: () {
                    ref.read(paymentRequestsNotifierProvider.notifier).refresh();
                    ref.invalidate(walletBalancesProvider);
                  },
                ),
              ],
            ),
            data: (cfg) => ListView(
              controller: _scroll,
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
              physics: ListPerf.listPhysics,
              children: [
                wallet.when(
                  data: (b) => ProGlassCard(
                    blur: 12,
                    animateIn: false,
                    padding: EdgeInsets.zero,
                    child: CfcBalanceHeader(cfc: b.cfc),
                  ),
                  loading: () => const SizedBox.shrink(),
                  error: (e, _) => Text(
                    ApiException.userMessage(e),
                    style: TextStyle(color: context.colors.onSurfaceMuted),
                  ),
                ),
                const SizedBox(height: 16),
                const CurrencyUsageCard.cfc(),
                const SizedBox(height: 20),
                ProGlassCard(
                  blur: 14,
                  animateIn: false,
                  padding: const EdgeInsets.all(4),
                  child: CfcNativeCheckout(
                    config: cfg,
                    onSubmitted: () {
                      ref.read(paymentRequestsNotifierProvider.notifier).refresh();
                      ref.invalidate(walletBalancesProvider);
                    },
                  ),
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
                    final cfcRows = rows.where((r) => r.isCfc).toList();
                    if (cfcRows.isEmpty) {
                      return Text(
                        'Henüz CFC talebi yok.',
                        style: TextStyle(
                          color: context.colors.onSurfaceMuted.withValues(alpha: 0.9),
                        ),
                      );
                    }
                    final hasMore =
                        ref.read(paymentRequestsNotifierProvider.notifier).hasMore;
                    return Column(
                      children: [
                        ...cfcRows.map((r) => _HistoryTile(row: r)),
                        if (hasMore)
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 12),
                            child: SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          ),
                      ],
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

}

class _HistoryTile extends StatelessWidget {
  const _HistoryTile({required this.row});

  final CfcPaymentRequestEntity row;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: ProGlassListTile(
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    row.displayLine,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  Text(
                    _statusTr(row.status),
                    style: TextStyle(
                      fontSize: 12,
                      color: AppThemeColors.diamondBlue.withValues(alpha: 0.9),
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              _statusIcon(row.status),
              color: _statusColor(row.status),
              size: 22,
            ),
          ],
        ),
      ),
    );
  }
}

String _statusTr(String s) => switch (s) {
      'approved' => 'Onaylandı — CFC yansıdı',
      'rejected' => 'Reddedildi',
      _ => 'Onay bekliyor',
    };

IconData _statusIcon(String s) => switch (s) {
      'approved' => Icons.check_circle_rounded,
      'rejected' => Icons.cancel_rounded,
      _ => Icons.schedule_rounded,
    };

Color _statusColor(String s) => switch (s) {
      'approved' => AppThemeColors.accentCyan,
      'rejected' => AppThemeColors.liveRed,
      _ => AppThemeColors.diamondBlue,
    };
