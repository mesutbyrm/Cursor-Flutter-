import 'package:canlifal_social/core/performance/widget_perf.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('CancellableDelay runs callback once', () async {
    var ran = false;
    WidgetPerf.delay(const Duration(milliseconds: 10), () => ran = true);
    await Future<void>.delayed(const Duration(milliseconds: 30));
    expect(ran, isTrue);
  });

  test('CancellableDelay cancel prevents callback', () async {
    var ran = false;
    final handle = WidgetPerf.delay(const Duration(milliseconds: 20), () {
      ran = true;
    });
    handle.cancel();
    await Future<void>.delayed(const Duration(milliseconds: 40));
    expect(ran, isFalse);
  });
}
