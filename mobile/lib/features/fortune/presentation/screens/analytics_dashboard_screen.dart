import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../providers/analytics_provider.dart';

class AnalyticsDashboardScreen extends ConsumerWidget {
  const AnalyticsDashboardScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Analitik & İstatistikler'),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildMetricsSection(ref),
            const SizedBox(height: 24),
            _buildTrendSection(ref),
            const SizedBox(height: 24),
            _buildRecommendationsSection(ref),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricsSection(WidgetRef ref) {
    return Consumer(
      builder: (context, ref, child) {
        final metricsAsync = ref.watch(userMetricsProvider);

        return metricsAsync.when(
          data: (metrics) => Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Özet İstatistikler',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                GridView.count(
                  crossAxisCount: 2,
                  childAspectRatio: 1.2,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  children: [
                    _buildMetricCard(
                      '${metrics.totalReadings}',
                      'Toplam Okumalar',
                      Icons.book,
                      Colors.blue,
                    ),
                    _buildMetricCard(
                      '${metrics.totalVoiceReadings}',
                      'Sesli Okumalar',
                      Icons.mic,
                      Colors.purple,
                    ),
                    _buildMetricCard(
                      '${metrics.currentStreak}',
                      'Günlük Seri',
                      Icons.local_fire_department,
                      Colors.orange,
                    ),
                    _buildMetricCard(
                      '${metrics.totalMatches}',
                      'Eşleştirmeler',
                      Icons.favorite,
                      Colors.pink,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        Column(
                          children: [
                            Text(
                              '${metrics.engagementScore.toInt()}',
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.cyan,
                              ),
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              'Katılım Puanı',
                              style: TextStyle(fontSize: 12),
                            ),
                          ],
                        ),
                        Column(
                          children: [
                            Text(
                              '${metrics.retentionScore.toInt()}',
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.cyan,
                              ),
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              'Saklama Puanı',
                              style: TextStyle(fontSize: 12),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, stack) => Center(child: Text('Hata: $err')),
        );
      },
    );
  }

  Widget _buildTrendSection(WidgetRef ref) {
    return Consumer(
      builder: (context, ref, child) {
        final trendAsync = ref.watch(engagementTrendProvider(30));

        return trendAsync.when(
          data: (trend) => Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Son 30 Günlük Trend',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (trend.isNotEmpty)
                          Container(
                            height: 200,
                            color: Colors.grey[100],
                            child: Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.show_chart,
                                    size: 48,
                                    color: Colors.cyan[200],
                                  ),
                                  const SizedBox(height: 8),
                                  const Text(
                                    'Grafik gösterimi yakında gelecek',
                                    style: TextStyle(color: Colors.grey),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        const SizedBox(height: 16),
                        ...trend.take(5).map((data) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  DateFormat('d MMM', 'tr_TR')
                                      .format(data['date'] as DateTime),
                                ),
                                Expanded(
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 12),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(4),
                                      child: LinearProgressIndicator(
                                        value: (data['engagementScore'] as num).toDouble() / 100,
                                        minHeight: 8,
                                        backgroundColor: Colors.grey[200],
                                        valueColor: const AlwaysStoppedAnimation(Colors.cyan),
                                      ),
                                    ),
                                  ),
                                ),
                                Text(
                                  '${(data['readings'] as int) + (data['voicereadings'] as int)}',
                                  style: const TextStyle(fontWeight: FontWeight.w600),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, stack) => Center(child: Text('Hata: $err')),
        );
      },
    );
  }

  Widget _buildRecommendationsSection(WidgetRef ref) {
    return Consumer(
      builder: (context, ref, child) {
        final reportAsync = ref.watch(analyticsReportProvider);

        return reportAsync.when(
          data: (report) {
            final recommendations = (report['recommendations'] as List?) ?? [];

            return Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Öneriler',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ...recommendations.map((rec) {
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      color: Colors.cyan[50],
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          children: [
                            Icon(Icons.lightbulb, color: Colors.cyan[400]),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                rec as String,
                                style: const TextStyle(fontSize: 13),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ],
              ),
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, stack) => Center(child: Text('Hata: $err')),
        );
      },
    );
  }

  Widget _buildMetricCard(String value, String label, IconData icon, Color color) {
    return Card(
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            colors: [color.withOpacity(0.1), Colors.white],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 11,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
