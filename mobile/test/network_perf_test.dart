import 'package:canlifal_social/core/performance/network_perf.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('parallel runs futures concurrently', () async {
    final order = <int>[];
    final results = await NetworkPerf.parallel([
      Future<void>.delayed(const Duration(milliseconds: 20), () {
        order.add(2);
      }),
      Future<void>.delayed(const Duration(milliseconds: 10), () {
        order.add(1);
      }),
    ]);
    expect(results, hasLength(2));
    expect(order.first, 1);
  });

  test('waitSilent completes despite individual failures', () async {
    var ok = false;
    await NetworkPerf.waitSilent([
      Future<void>.error(Exception('fail')),
      Future<void>(() async {
        ok = true;
      }),
    ]);
    expect(ok, isTrue);
  });
}
