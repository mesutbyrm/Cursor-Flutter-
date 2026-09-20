import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme_colors.dart';
import '../../../../core/theme/app_theme_extensions.dart';
import '../../../../core/widgets/discover_tab_layout.dart';
import '../../../feed/presentation/widgets/discover/discover_background.dart';
import '../providers/admin_system_health_providers.dart';
import '../providers/staff_access_provider.dart';

/// Sistem sağlığı panosu - istatistikler ve performans metrikleri.
class AdminSystemHealthPage extends ConsumerWidget {
  const AdminSystemHealthPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final access = ref.watch(staffAccessProvider);
    if (!access.isSiteAdmin) {
      return Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: DiscoverBackground(
          child: Center(
            child: DiscoverEmptyState(
              icon: Icons.lock_outline_rounded,
              message: 'Sistem sağlığı görüntüleme yetkisi gerekli.',
              actionLabel: 'Geri',
              action: () => Navigator.of(context).maybePop(),
            ),
          ),
        ),
      );
    }

    final healthAsync = ref.watch(adminSystemHealthProvider);
    final statsAsync = ref.watch(adminDailyStatsProvider);

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
                      title: 'Sistem Sağlığı',
                      subtitle: 'Performans ve istatistikler',
                    ),
                  ),
                  DiscoverIconButton(
                    icon: Icons.refresh_rounded,
                    onPressed: () {
                      ref.invalidate(adminSystemHealthProvider);
                      ref.invalidate(adminDailyStatsProvider);
                    },
                  ),
                ],
              ),
            ),
            Expanded(
              child: RefreshIndicator(
                color: AppThemeColors.accentPink,
                onRefresh: () async {
                  ref.invalidate(adminSystemHealthProvider);
                  ref.invalidate(adminDailyStatsProvider);
                },
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
                  children: [
                    // Genel Durum
                    healthAsync.when(
                      data: (health) {
                        final status = calculateHealthStatus(health);
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _SectionTitle('Genel Durum'),
                            _HealthStatusCard(
                              status: status,
                              health: health,
                            ),
                            const SizedBox(height: 24),
                          ],
                        );
                      },
                      loading: () => const Padding(
                        padding: EdgeInsets.all(16.0),
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                      error: (e, _) => Center(
                        child: DiscoverEmptyState(
                          icon: Icons.error_outline_rounded,
                          message: 'Sistem durumu yüklenemedi',
                        ),
                      ),
                    ),

                    // Performans Metrikleri
                    healthAsync.when(
                      data: (health) => Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _SectionTitle('Performans Metrikleri'),
                          _MetricCard(
                            icon: Icons.speed_rounded,
                            label: 'API Yanıt Süresi',
                            value: '${health.apiResponseTime.toStringAsFixed(1)}ms',
                            status: health.apiResponseTime < 100
                                ? 'excellent'
                                : health.apiResponseTime < 300
                                    ? 'good'
                                    : 'poor',
                          ),
                          _MetricCard(
                            icon: Icons.storage_rounded,
                            label: 'Veritabanı Yükü',
                            value: '${health.databaseLoadPercentage.toStringAsFixed(1)}%',
                            status: health.databaseLoadPercentage < 50
                                ? 'excellent'
                                : health.databaseLoadPercentage < 80
                                    ? 'good'
                                    : 'poor',
                          ),
                          _MetricCard(
                            icon: Icons.error_outline_rounded,
                            label: 'Hata Oranı',
                            value: '${health.errorRate.toStringAsFixed(2)}%',
                            status: health.errorRate < 1
                                ? 'excellent'
                                : health.errorRate < 5
                                    ? 'good'
                                    : 'poor',
                          ),
                          const SizedBox(height: 24),
                        ],
                      ),
                      loading: () => const SizedBox.shrink(),
                      error: (e, _) => const SizedBox.shrink(),
                    ),

                    // Kullanıcı İstatistikleri
                    healthAsync.when(
                      data: (health) => Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _SectionTitle('Kullanıcı İstatistikleri'),
                          Row(
                            children: [
                              Expanded(
                                child: _StatBox(
                                  label: 'Toplam Kullanıcı',
                                  value: '${health.totalUsers}',
                                  icon: Icons.people_rounded,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _StatBox(
                                  label: 'Aktif Kullanıcı',
                                  value: '${health.activeUsers}',
                                  icon: Icons.person_check_rounded,
                                  color: AppThemeColors.accentCyan,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: _StatBox(
                                  label: 'Toplam İşlem',
                                  value: '${health.totalTransactions}',
                                  icon: Icons.swap_horiz_rounded,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _StatBox(
                                  label: 'Bekleyen İşlemler',
                                  value: '${health.pendingOperations}',
                                  icon: Icons.hourglass_bottom_rounded,
                                  color: AppThemeColors.accentPink,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),
                        ],
                      ),
                      loading: () => const SizedBox.shrink(),
                      error: (e, _) => const SizedBox.shrink(),
                    ),

                    // Günlük İstatistikler
                    _SectionTitle('7 Günlük Trend'),
                    statsAsync.when(
                      data: (stats) {
                        if (stats.isEmpty) {
                          return Center(
                            child: DiscoverEmptyState(
                              icon: Icons.bar_chart_rounded,
                              message: 'İstatistik verisi yok',
                            ),
                          );
                        }
                        return Column(
                          children: stats.map((stat) {
                            return _DailyStatCard(stat: stat);
                          }).toList(),
                        );
                      },
                      loading: () => const Center(
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                      error: (e, _) => Center(
                        child: DiscoverEmptyState(
                          icon: Icons.error_outline_rounded,
                          message: 'İstatistikler yüklenemedi',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        text,
        style: TextStyle(
          fontWeight: FontWeight.w800,
          fontSize: 15,
          color: context.colors.onSurface,
        ),
      ),
    );
  }
}

class _HealthStatusCard extends StatelessWidget {
  const _HealthStatusCard({
    required this.status,
    required this.health,
  });

  final HealthStatus status;
  final AdminSystemHealth health;

  Color _getStatusColor(HealthStatus status) {
    switch (status) {
      case HealthStatus.excellent:
        return AppThemeColors.accentCyan;
      case HealthStatus.good:
        return Colors.green;
      case HealthStatus.fair:
        return AppThemeColors.accentPink;
      case HealthStatus.poor:
        return Colors.orange;
      case HealthStatus.critical:
        return AppThemeColors.liveRed;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _getStatusColor(status);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        border: Border.all(color: color.withValues(alpha: 0.3)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.monitor_heart_rounded,
                color: color,
                size: 24,
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    healthStatusLabel(status),
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                      color: context.colors.onSurface,
                    ),
                  ),
                  Text(
                    'Son güncelleme: ${health.lastUpdated}',
                    style: TextStyle(
                      fontSize: 10,
                      color: context.colors.onSurfaceMuted,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.status,
  });

  final IconData icon;
  final String label;
  final String value;
  final String status;

  Color _getStatusColor() {
    switch (status) {
      case 'excellent':
        return AppThemeColors.accentCyan;
      case 'good':
        return Colors.green;
      case 'poor':
        return AppThemeColors.liveRed;
      default:
        return AppThemeColors.accentPink;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _getStatusColor();
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: context.colors.surfaceContainer,
        border: Border.all(
          color: color.withValues(alpha: 0.3),
        ),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: context.colors.onSurfaceMuted,
                  ),
                ),
                Text(
                  value,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    color: context.colors.onSurface,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              status.toUpperCase(),
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatBox extends StatelessWidget {
  const _StatBox({
    required this.label,
    required this.value,
    required this.icon,
    this.color = AppThemeColors.accentPink,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        border: Border.all(color: color.withValues(alpha: 0.3)),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 14,
              color: context.colors.onSurface,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 9,
              color: context.colors.onSurfaceMuted,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _DailyStatCard extends StatelessWidget {
  const _DailyStatCard({required this.stat});

  final DailyStat stat;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: context.colors.surfaceContainer,
        border: Border.all(
          color: AppThemeColors.accentCyan.withValues(alpha: 0.2),
        ),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            stat.date,
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 12,
              color: context.colors.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _MiniStat(
                  label: 'Yeni Üye',
                  value: '${stat.newUsers}',
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _MiniStat(
                  label: 'Aktif',
                  value: '${stat.activeUsers}',
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _MiniStat(
                  label: 'İşlem',
                  value: '${stat.transactions}',
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _MiniStat(
                  label: 'Gelir',
                  value: '₺${stat.revenue.toStringAsFixed(0)}',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  const _MiniStat({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 12,
            color: AppThemeColors.accentCyan,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 9,
            color: context.colors.onSurfaceMuted,
          ),
        ),
      ],
    );
  }
}
