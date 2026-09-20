import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme_colors.dart';
import '../../../../core/theme/app_theme_extensions.dart';
import '../../../../core/widgets/discover_tab_layout.dart';
import '../../../feed/presentation/widgets/discover/discover_background.dart';
import '../providers/admin_fraud_detection_providers.dart';
import '../providers/staff_access_provider.dart';

/// Admin fraud detection — suspicious patterns & high-risk transactions.
class AdminFraudDetectionPage extends ConsumerStatefulWidget {
  const AdminFraudDetectionPage({super.key});

  @override
  ConsumerState<AdminFraudDetectionPage> createState() =>
      _AdminFraudDetectionPageState();
}

class _AdminFraudDetectionPageState
    extends ConsumerState<AdminFraudDetectionPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  void _refresh() {
    ref.invalidate(adminFraudDetectionProvider);
    ref.invalidate(adminHighRiskTransactionsProvider);
  }

  @override
  Widget build(BuildContext context) {
    final access = ref.watch(staffAccessProvider);
    if (!access.canManagePayments) {
      return Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: DiscoverBackground(
          child: Center(
            child: DiscoverEmptyState(
              icon: Icons.lock_outline_rounded,
              message: 'Dolandırıcılık tespiti yetkisi gerekli.',
              actionLabel: 'Geri',
              action: () => Navigator.of(context).maybePop(),
            ),
          ),
        ),
      );
    }

    final alertsAsync = ref.watch(adminFraudDetectionProvider);
    final transactionsAsync = ref.watch(adminHighRiskTransactionsProvider);
    final alertCount = ref.watch(adminFraudAlertCountProvider);
    final transactionCount = ref.watch(adminHighRiskTransactionCountProvider);

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
                    onPressed: () => Navigator.of(context).maybePop(),
                  ),
                  Expanded(
                    child: DiscoverTabHeader(
                      title: 'Fraud Detection',
                      subtitle: 'Suspicious patterns & risk analysis',
                    ),
                  ),
                  DiscoverIconButton(
                    icon: Icons.refresh_rounded,
                    onPressed: _refresh,
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
              child: TabBar(
                controller: _tabs,
                indicatorColor: AppThemeColors.accentPink,
                labelColor: Colors.white,
                unselectedLabelColor: context.colors.onSurfaceMuted,
                tabs: [
                  Tab(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text('Fraud Alerts'),
                        if (alertCount > 0) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: AppThemeColors.liveRed,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              '$alertCount',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: 10,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  Tab(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text('High-Risk'),
                        if (transactionCount > 0) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: AppThemeColors.accentPink,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              '$transactionCount',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: 10,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: TabBarView(
                controller: _tabs,
                children: [
                  _FraudAlertsTab(
                    alertsAsync: alertsAsync,
                    onRefresh: _refresh,
                  ),
                  _HighRiskTransactionsTab(
                    transactionsAsync: transactionsAsync,
                    onRefresh: _refresh,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FraudAlertsTab extends StatelessWidget {
  const _FraudAlertsTab({
    required this.alertsAsync,
    required this.onRefresh,
  });

  final AsyncValue<List<Map<String, dynamic>>> alertsAsync;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    return alertsAsync.when(
      data: (alerts) {
        if (alerts.isEmpty) {
          return Center(
            child: DiscoverEmptyState(
              icon: Icons.verified_rounded,
              message: 'Dolandırıcılık uyarısı yok.',
            ),
          );
        }
        return RefreshIndicator(
          color: AppThemeColors.accentPink,
          onRefresh: () async => onRefresh(),
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
            itemCount: alerts.length,
            itemBuilder: (context, i) {
              final alert = alerts[i];
              return _FraudAlertCard(alert: alert);
            },
          ),
        );
      },
      loading: () => const Center(
        child: CircularProgressIndicator(strokeWidth: 2),
      ),
      error: (e, _) => Center(
        child: DiscoverEmptyState(
          icon: Icons.error_outline_rounded,
          message: 'Uyarı yüklenemedi',
          actionLabel: 'Tekrar Dene',
          action: onRefresh,
        ),
      ),
    );
  }
}

class _HighRiskTransactionsTab extends StatelessWidget {
  const _HighRiskTransactionsTab({
    required this.transactionsAsync,
    required this.onRefresh,
  });

  final AsyncValue<List<Map<String, dynamic>>> transactionsAsync;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    return transactionsAsync.when(
      data: (transactions) {
        if (transactions.isEmpty) {
          return Center(
            child: DiscoverEmptyState(
              icon: Icons.check_circle_rounded,
              message: 'Yüksek riskli işlem yok.',
            ),
          );
        }
        return RefreshIndicator(
          color: AppThemeColors.accentPink,
          onRefresh: () async => onRefresh(),
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
            itemCount: transactions.length,
            itemBuilder: (context, i) {
              final transaction = transactions[i];
              return _HighRiskTransactionCard(transaction: transaction);
            },
          ),
        );
      },
      loading: () => const Center(
        child: CircularProgressIndicator(strokeWidth: 2),
      ),
      error: (e, _) => Center(
        child: DiscoverEmptyState(
          icon: Icons.error_outline_rounded,
          message: 'İşlem yüklenemedi',
          actionLabel: 'Tekrar Dene',
          action: onRefresh,
        ),
      ),
    );
  }
}

class _FraudAlertCard extends StatelessWidget {
  const _FraudAlertCard({required this.alert});

  final Map<String, dynamic> alert;

  @override
  Widget build(BuildContext context) {
    final username = alert['username'] as String?;
    final alertType = alert['alert_type'] as String?;
    final riskLevel = alert['risk_level'] as String? ?? 'medium';
    final details = alert['details'] as String?;
    final detectedAt = alert['detected_at'] as String?;
    final reviewed = alert['reviewed'] as bool? ?? false;

    final type = parseFraudAlertType(alertType);
    final level = parseRiskLevel(riskLevel);
    final levelColor = _getRiskLevelColor(level);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: reviewed
            ? context.colors.surfaceContainer.withValues(alpha: 0.5)
            : context.colors.surfaceContainer,
        border: Border.all(
          color: levelColor.withValues(alpha: 0.3),
        ),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.warning_rounded,
                color: levelColor,
                size: 18,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      username ?? 'Bilinmiyor',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                        color: context.colors.onSurface,
                      ),
                    ),
                    Text(
                      fraudAlertTypeLabel(type),
                      style: TextStyle(
                        fontSize: 11,
                        color: levelColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: levelColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  riskLevelLabel(level),
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    color: levelColor,
                  ),
                ),
              ),
            ],
          ),
          if (details != null && details.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              details,
              style: TextStyle(
                fontSize: 11,
                color: context.colors.onSurface,
                height: 1.4,
              ),
            ),
          ],
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (detectedAt != null)
                Text(
                  detectedAt.substring(0, 10),
                  style: TextStyle(
                    fontSize: 10,
                    color: context.colors.onSurfaceMuted,
                  ),
                ),
              if (reviewed)
                Chip(
                  label: const Text('Gözden geçirildi'),
                  labelStyle: const TextStyle(fontSize: 9),
                  backgroundColor: AppThemeColors.accentCyan.withValues(alpha: 0.2),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Color _getRiskLevelColor(RiskLevel level) {
    switch (level) {
      case RiskLevel.low:
        return AppThemeColors.accentCyan;
      case RiskLevel.medium:
        return AppThemeColors.accentPink;
      case RiskLevel.high:
        return AppThemeColors.liveRed;
      case RiskLevel.critical:
        return Color.fromARGB(255, 139, 0, 0);
    }
  }
}

class _HighRiskTransactionCard extends StatelessWidget {
  const _HighRiskTransactionCard({required this.transaction});

  final Map<String, dynamic> transaction;

  @override
  Widget build(BuildContext context) {
    final username = transaction['username'] as String?;
    final transactionType = transaction['transaction_type'] as String?;
    final amount = transaction['amount'] as num?;
    final reason = transaction['reason'] as String?;
    final timestamp = transaction['timestamp'] as String?;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: context.colors.surfaceContainer,
        border: Border.all(
          color: AppThemeColors.accentPink.withValues(alpha: 0.3),
        ),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.trending_up_rounded,
                color: AppThemeColors.accentPink,
                size: 18,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      username ?? 'Bilinmiyor',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                        color: context.colors.onSurface,
                      ),
                    ),
                    Text(
                      transactionType ?? 'Unknown',
                      style: TextStyle(
                        fontSize: 11,
                        color: context.colors.onSurfaceMuted,
                      ),
                    ),
                  ],
                ),
              ),
              if (amount != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppThemeColors.accentPink.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '₺${amount.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppThemeColors.accentPink,
                    ),
                  ),
                ),
            ],
          ),
          if (reason != null && reason.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              reason,
              style: TextStyle(
                fontSize: 11,
                color: context.colors.onSurface,
                height: 1.4,
              ),
            ),
          ],
          const SizedBox(height: 8),
          if (timestamp != null)
            Text(
              timestamp,
              style: TextStyle(
                fontSize: 10,
                color: context.colors.onSurfaceMuted,
              ),
            ),
        ],
      ),
    );
  }
}
