import 'package:canlifal_social/core/performance/app_perf_metrics.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('AppPerfMetrics records slowest entries', () {
    AppPerfMetrics.clear();
    AppPerfMetrics.recordApi('/api/me', 450);
    AppPerfMetrics.recordApi('/api/wallet', 120);
    AppPerfMetrics.recordRoute('/home', '/fortune', 280);

    final slow = AppPerfMetrics.slowest(limit: 2, group: 'api');
    expect(slow.length, 2);
    expect(slow.first.name, '/api/me');
    expect(slow.first.durationMs, 450);
  });
}
