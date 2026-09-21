import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/performance_monitoring_provider.dart';

class PerformanceMonitoringScreen extends ConsumerWidget {
  const PerformanceMonitoringScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Performans'),
        elevation: 0,
      ),
      body: Consumer(
        builder: (context, ref, child) {
          final metricsAsync = ref.watch(performanceMetricsProvider(''));
          final reportAsync = ref.watch(performanceReportProvider(''));

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Performans Ölçümleri',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                metricsAsync.when(
                  data: (metrics) {
                    return Card(
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          children: [
                            _buildMetricRow(
                              'Uygulama Açılış Süresi',
                              '${metrics.appOpenTime ?? 0}ms',
                            ),
                            _buildMetricRow(
                              'Sayfa Yükleme Süresi',
                              '${metrics.pageLoadTime ?? 0}ms',
                            ),
                            _buildMetricRow(
                              'API Yanıt Süresi',
                              '${metrics.apiResponseTime ?? 0}ms',
                            ),
                            _buildMetricRow(
                              'Pil Tüketimi',
                              '${metrics.batteryUsage ?? 0}%',
                            ),
                            _buildMetricRow(
                              'Veri Kullanımı',
                              '${metrics.dataUsage ?? 0}MB',
                            ),
                            _buildMetricRow(
                              'Bellek Kullanımı',
                              '${metrics.memoryUsage ?? 0}MB',
                            ),
                            _buildMetricRow(
                              'Çökme Sayısı',
                              '${metrics.crashCount ?? 0}',
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                  loading: () => const CircularProgressIndicator(),
                  error: (err, stack) => Text('Hata: $err'),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Öneriler',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                reportAsync.when(
                  data: (report) {
                    final recommendations = report['recommendations'] as List? ?? [];
                    return Column(
                      children: recommendations.isEmpty
                          ? [
                              const Text(
                                'Performans iyi görünüyor',
                                style: TextStyle(color: Colors.green),
                              ),
                            ]
                          : recommendations
                              .map((rec) => Card(
                                    margin: const EdgeInsets.only(bottom: 8),
                                    color: Colors.amber[50],
                                    child: Padding(
                                      padding: const EdgeInsets.all(12),
                                      child: Row(
                                        children: [
                                          Icon(Icons.lightbulb, color: Colors.amber[700]),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Text(rec as String),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ))
                              .toList(),
                    );
                  },
                  loading: () => const CircularProgressIndicator(),
                  error: (err, stack) => Text('Hata: $err'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildMetricRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
