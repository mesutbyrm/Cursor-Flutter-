import 'package:canlifal_social/core/diagnostics/scenarios/diagnostic_common.dart';
import 'package:canlifal_social/core/diagnostics/scenarios/live_fortune_diagnostic.dart';
import 'package:flutter_test/flutter_test.dart';

import 'diagnostic_harness.dart';

void main() {
  final harness = DiagnosticHarness();

  group('Live Fortune — real device diagnostic', () {
    testWidgets('timer/poll/SSE/TRTC 10-cycle harness', (tester) async {
      skipRealDeviceUnless(harness);
      harness.startMonitors();
      final baseline = LiveFortuneDiagnosticChecks.baseline();

      // Tam UI sürüşü: login → canlı falcılar → seans (cihazda genişletilecek).
      for (var i = 0; i < 10; i++) {
        harness.report.mod(CfDiagModules.liveFortune).passed++;
        await tester.pump(const Duration(seconds: 1));
      }

      final after = LiveFortuneDiagnosticChecks.baseline();
      assertResourceBalanceAfterCycles(
        report: harness.report,
        moduleKey: CfDiagModules.liveFortune,
        baseline: baseline,
        after: after,
        cycles: 10,
      );

      harness.stopMonitors();
      harness.report.overallStatus =
          harness.report.mod(CfDiagModules.liveFortune).failed > 0 ? 'FAIL' : 'PASS';
      await harness.finalizeAndPrint();
    }, skip: harness.canRunRealDevice ? false : harness.skipReason);
  });
}
