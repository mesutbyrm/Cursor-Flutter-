import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/network/api_exception.dart';
import '../../../../core/theme/app_theme_colors.dart';
import '../../../../core/widgets/discover_tab_layout.dart';
import '../../../feed/presentation/widgets/discover/discover_background.dart';
import '../providers/admin_module_ui_store.dart';
import '../providers/admin_finance_summary_providers.dart';
import '../providers/staff_access_provider.dart';

class AdminFinanceSummaryPage extends ConsumerStatefulWidget {
  const AdminFinanceSummaryPage({super.key});

  @override
  ConsumerState<AdminFinanceSummaryPage> createState() =>
      _AdminFinanceSummaryPageState();
}

class _AdminFinanceSummaryPageState extends ConsumerState<AdminFinanceSummaryPage> {
  static const _uiModule = 'admin.finance';

  String _period = 'monthly';

  @override
  void initState() {
    super.initState();
    unawaited(_restorePeriod());
  }

  Future<void> _restorePeriod() async {
    final ui = await AdminModuleUiStore.loadAll();
    final saved = AdminModuleUiStore.filterFor(ui, _uiModule);
    if (saved != null && saved.isNotEmpty && mounted) {
      setState(() => _period = saved);
    }
  }

  @override
  Widget build(BuildContext context) {
    final access = ref.watch(staffAccessProvider);
    if (!access.canManagePayments) {
      return Scaffold(
        body: DiscoverBackground(
          child: Center(
            child: DiscoverEmptyState(
              icon: Icons.lock_outline_rounded,
              message: 'Finans özeti için yetkiniz yok.',
              actionLabel: 'Geri',
              action: () => Navigator.of(context).maybePop(),
            ),
          ),
        ),
      );
    }

    final async = ref.watch(adminFinanceSummaryProvider(_period));
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: DiscoverBackground(
        child: Column(
          children: [
            SizedBox(height: MediaQuery.paddingOf(context).top + 4),
            Padding(
              padding: const EdgeInsets.only(left: 4, right: 12),
              child: Row(
                children: [
                  DiscoverIconButton(
                    icon: Icons.arrow_back_ios_new_rounded,
                    onPressed: () => context.pop(),
                  ),
                  const Expanded(
                    child: DiscoverTabHeader(
                      title: 'Finans Özeti',
                      subtitle: 'Gelir, harcama ve net',
                    ),
                  ),
                  DiscoverIconButton(
                    icon: Icons.refresh_rounded,
                    onPressed: () =>
                        ref.invalidate(adminFinanceSummaryProvider(_period)),
                  ),
                ],
              ),
            ),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  for (final p in const ['daily', 'weekly', 'monthly', 'yearly'])
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: FilterChip(
                        label: Text(p),
                        selected: _period == p,
                        onSelected: (_) {
                          setState(() => _period = p);
                          unawaited(AdminModuleUiStore.saveFilter(_uiModule, p));
                        },
                      ),
                    ),
                ],
              ),
            ),
            Expanded(
              child: async.when(
                data: (s) => ListView(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
                  children: [
                    _MetricCard(
                      title: 'Gelir (TL)',
                      value: _fmtTl(s.revenueTotalTl),
                      subtitle: '${s.revenueTransactionCount} işlem',
                      color: AppThemeColors.accentCyan,
                    ),
                    const SizedBox(height: 12),
                    _MetricCard(
                      title: 'Hediye harcaması',
                      value: '${s.giftsTotal}',
                      subtitle: 'Jeton/CFC',
                      color: AppThemeColors.accentPink,
                    ),
                    const SizedBox(height: 12),
                    _MetricCard(
                      title: 'Çekimler (TL)',
                      value: _fmtTl(s.withdrawalsTotalTl),
                      subtitle: 'Onaylı çekimler',
                      color: AppThemeColors.coinGold,
                    ),
                    const SizedBox(height: 12),
                    _MetricCard(
                      title: 'Net gelir (TL)',
                      value: _fmtTl(s.netRevenueTl),
                      subtitle: 'Dönem: ${s.period}',
                      color: const Color(0xFF22C55E),
                    ),
                  ],
                ),
                loading: () =>
                    const Center(child: DiscoverAccentLoader()),
                error: (e, _) => Center(
                  child: DiscoverEmptyState(
                    icon: Icons.error_outline_rounded,
                    message: ApiException.userMessage(e),
                    actionLabel: 'Yenile',
                    action: () =>
                        ref.invalidate(adminFinanceSummaryProvider(_period)),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _fmtTl(double v) {
    if (v == v.roundToDouble()) return '${v.toStringAsFixed(0)} ₺';
    return '${v.toStringAsFixed(2)} ₺';
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.color,
  });

  final String title;
  final String value;
  final String subtitle;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(subtitle, style: const TextStyle(fontSize: 12)),
        ],
      ),
    );
  }
}
