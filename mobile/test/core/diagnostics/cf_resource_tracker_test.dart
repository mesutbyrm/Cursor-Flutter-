import 'package:canlifal_social/core/diagnostics/cf_resource_tracker.dart';
import 'package:canlifal_social/core/diagnostics/cf_root_cause.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  setUp(() {
    CfResourceTracker.resetForTest();
    CfRootCauseAnalyzer.resetForTest();
  });

  test('create and dispose balances', () {
    final id = CfResourceTracker.create(
      CfResourceKind.timer,
      module: 'live_fortune',
      label: 'tick',
    );
    expect(CfResourceTracker.snapshot().activeTimers, 1);
    CfResourceTracker.markDisposed(id);
    expect(CfResourceTracker.snapshot().activeTimers, 0);
    expect(CfResourceTracker.hasLeaks(module: 'live_fortune'), isFalse);
  });

  test('leak detection produces bug report', () {
    CfResourceTracker.create(
      CfResourceKind.poller,
      module: 'live_fortune',
      label: 'room_poll',
    );
    final leaks = CfResourceTracker.leaks(module: 'live_fortune');
    expect(leaks, isNotEmpty);
    final bug = CfRootCauseAnalyzer.fromResourceLeaks(
      module: 'LIVE FORTUNE',
      leaks: leaks,
    );
    expect(bug.category, contains('Polling'));
  });

  test('periodic timer cancel clears resource', () {
    final t = CfResourceTracker.periodic(
      const Duration(milliseconds: 100),
      (_) {},
      module: 'voice_room',
      label: 'heartbeat',
    );
    expect(CfResourceTracker.snapshot().activeTimers, 1);
    CfResourceTracker.cancelTimer(t.timer, t.resourceId);
    expect(CfResourceTracker.snapshot().activeTimers, 0);
  });
}
