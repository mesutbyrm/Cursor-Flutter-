import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_theme_colors.dart';
import '../../../../core/widgets/discover_tab_layout.dart';
import '../../../feed/presentation/widgets/discover/discover_background.dart';

/// Falcı Analitikleri — Seans, gelir, puan, trend panosu.
class PsychicAnalyticsScreen extends ConsumerWidget {
  const PsychicAnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Mock analytics data
    final analytics = {
      'totalSessions': 247,
      'totalEarnings': 12450.75,
      'avgRating': 4.8,
      'responseRate': 95,
      'completionRate': 92,
      'thisMonthSessions': 47,
      'thisMonthEarnings': 2150.50,
      'lastMonthSessions': 52,
      'lastMonthEarnings': 2380.25,
      'weekTrend': [8, 12, 10, 15, 14, 12, 8],
      'earningsTrend': [280, 320, 250, 380, 350, 290, 240],
    };

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
                      title: 'Analitikler',
                      subtitle: 'Seans, gelir ve performans özeti',
                    ),
                  ),
                  DiscoverIconButton(
                    icon: Icons.refresh_rounded,
                    onPressed: () {},
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                children: [
                  // Key metrics row
                  Row(
                    children: [
                      Expanded(
                        child: _MetricCard(
                          label: 'Toplam Seans',
                          value: '${analytics['totalSessions']}',
                          icon: Icons.video_call_rounded,
                          color: AppThemeColors.accentCyan,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _MetricCard(
                          label: 'Puanı',
                          value: '${analytics['avgRating']}',
                          icon: Icons.star_rounded,
                          color: Colors.amber,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _MetricCard(
                          label: 'Yanıt Hızı',
                          value: '${analytics['responseRate']}%',
                          icon: Icons.schedule_rounded,
                          color: Colors.green,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _MetricCard(
                          label: 'Tamamlanma',
                          value: '${analytics['completionRate']}%',
                          icon: Icons.check_circle_rounded,
                          color: Colors.purple,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // This month vs last month
                  const Text(
                    'Bu Ay vs Geçen Ay',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                      color: AppThemeColors.accentCyan,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _MonthComparisonCard(
                          month: 'Bu Ay',
                          sessions: analytics['thisMonthSessions'] as int,
                          earnings: analytics['thisMonthEarnings'] as double,
                          isActive: true,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _MonthComparisonCard(
                          month: 'Geçen Ay',
                          sessions: analytics['lastMonthSessions'] as int,
                          earnings: analytics['lastMonthEarnings'] as double,
                          isActive: false,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Weekly trend
                  const Text(
                    'Haftalık Seans Trendi',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                      color: AppThemeColors.accentCyan,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Card(
                    color: AppThemeColors.accentCyan.withValues(alpha: 0.08),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: _TrendChart(
                        data: analytics['weekTrend'] as List<int>,
                        days: ['Pzt', 'Sal', 'Çar', 'Perş', 'Cum', 'Cmt', 'Paz'],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Weekly earnings
                  Card(
                    color: Colors.green.withValues(alpha: 0.08),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: _TrendChart(
                        data: (analytics['earningsTrend'] as List<int>)
                            .map((e) => (e / 10).ceil())
                            .toList(),
                        days: ['Pzt', 'Sal', 'Çar', 'Perş', 'Cum', 'Cmt', 'Paz'],
                        label: '₺ (×10)',
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Top actions
                  const Text(
                    'İşlemler',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                      color: AppThemeColors.accentCyan,
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      icon: const Icon(Icons.download_rounded),
                      label: const Text('Raporu İndir (CSV)'),
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Rapor indirildi')),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.share_rounded),
                      label: const Text('Paylaş'),
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Paylaş menüsü açılacak')),
                        );
                      },
                    ),
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

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: color.withValues(alpha: 0.1),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 18,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(
                fontSize: 10,
                color: Colors.white70,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MonthComparisonCard extends StatelessWidget {
  const _MonthComparisonCard({
    required this.month,
    required this.sessions,
    required this.earnings,
    required this.isActive,
  });

  final String month;
  final int sessions;
  final double earnings;
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: isActive
          ? AppThemeColors.accentCyan.withValues(alpha: 0.12)
          : Colors.grey.withValues(alpha: 0.08),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              month,
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 12,
                color: isActive ? AppThemeColors.accentCyan : Colors.white70,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Seanslar',
                      style: TextStyle(fontSize: 9, color: Colors.white60),
                    ),
                    Text(
                      '$sessions',
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text(
                      'Gelir',
                      style: TextStyle(fontSize: 9, color: Colors.white60),
                    ),
                    Text(
                      '₺${earnings.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                        color: Colors.green,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _TrendChart extends StatelessWidget {
  const _TrendChart({
    required this.data,
    required this.days,
    this.label = 'Seanslar',
  });

  final List<int> data;
  final List<String> days;
  final String label;

  @override
  Widget build(BuildContext context) {
    final maxValue = data.reduce((a, b) => a > b ? a : b).toDouble();
    final height = 100.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 10,
            color: Colors.white60,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: height,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: List.generate(
              data.length,
              (i) {
                final ratio = data[i] / maxValue;
                return Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Flexible(
                        child: Container(
                          width: double.infinity,
                          height: height * ratio,
                          margin: const EdgeInsets.symmetric(horizontal: 2),
                          decoration: BoxDecoration(
                            color: AppThemeColors.accentCyan.withValues(
                              alpha: 0.6 + (ratio * 0.4),
                            ),
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(4),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        days[i],
                        style: const TextStyle(
                          fontSize: 9,
                          color: Colors.white60,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}
