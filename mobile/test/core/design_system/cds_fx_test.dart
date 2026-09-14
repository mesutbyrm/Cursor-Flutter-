import 'package:canlifal_social/core/design_system/cds_fx.dart';
import 'package:canlifal_social/core/design_system/cds_overlay_priority.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
  });

  test('CdsFxNotifier performance mode toggles', () async {
    final container = ProviderContainer();
    final notifier = container.read(cdsFxProvider.notifier);
    expect(container.read(cdsFxProvider).performanceMode, isFalse);
    await notifier.setPerformanceMode(true);
    expect(container.read(cdsFxProvider).performanceMode, isTrue);
    container.dispose();
  });

  test('CdsFullscreenGiftGate blocks second acquire', () {
    final gate = CdsFullscreenGiftGate.instance;
    expect(gate.tryAcquire('a'), isTrue);
    expect(gate.tryAcquire('b'), isFalse);
    gate.release('a');
    expect(gate.tryAcquire('b'), isTrue);
    gate.release('b');
  });
}
