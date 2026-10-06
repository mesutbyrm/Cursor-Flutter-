import 'package:canlifal_social/core/diagnostics/scenarios/diagnostic_common.dart';
import 'package:flutter_test/flutter_test.dart';

import 'diagnostic_harness.dart';

void main() {
  final harness = DiagnosticHarness();

  testWidgets('Voice room — A/B room 10-cycle (stub harness)', (tester) async {
    skipRealDeviceUnless(harness);
    harness.markModuleNotRun(CfDiagModules.voiceRoom,
        note: 'UI tour not automated yet — harness ready');
    harness.report.overallStatus = 'NOT RUN';
    await harness.finalizeAndPrint();
  }, skip: harness.canRunRealDevice ? false : harness.skipReason);
}
