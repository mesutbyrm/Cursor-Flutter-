import 'package:canlifal_social/core/auth/refresh_me_gate.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('RefreshMeGate', () {
    late RefreshMeGate gate;

    setUp(() => gate = RefreshMeGate(minInterval: const Duration(seconds: 2)));

    test('dedupes concurrent refresh calls', () async {
      var calls = 0;
      Future<void> slow() async {
        calls++;
        await Future<void>.delayed(const Duration(milliseconds: 50));
      }

      final a = gate.run(slow);
      final b = gate.run(slow);
      await Future.wait([a, b]);
      expect(calls, 1);
    });

    test('throttles rapid sequential calls', () async {
      var calls = 0;
      Future<void> tick() async => calls++;

      await gate.run(tick);
      await gate.run(tick);
      expect(calls, 1);
    });

    test('force bypasses throttle and in-flight', () async {
      var calls = 0;
      Future<void> tick() async {
        calls++;
        await Future<void>.delayed(const Duration(milliseconds: 30));
      }

      final inFlight = gate.run(tick);
      await gate.run(tick, force: true);
      await inFlight;
      expect(calls, 2);
    });
  });
}
