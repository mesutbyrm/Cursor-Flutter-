/// Canlifal gerçek cihaz diagnostic — ortak sabitler ve yardımcılar.
library;

import '../cf_diagnostic_report.dart';
import '../cf_resource_tracker.dart';
import '../cf_root_cause.dart';

export '../cf_diagnostic_report.dart';
export '../cf_resource_tracker.dart';
export '../cf_root_cause.dart';
export '../cf_diag.dart';
export '../cf_monitors.dart';
export '../cf_trace.dart';

abstract final class CfDiagModules {
  static const liveFortune = 'LIVE FORTUNE';
  static const liveStream = 'LIVE STREAM';
  static const voiceRoom = 'VOICE ROOM';
  static const globalApp = 'GLOBAL APP';
}

CfModuleResult assertResourceBalanceAfterCycles({
  required CfDiagnosticReport report,
  required String moduleKey,
  required CfResourceSnapshot baseline,
  required CfResourceSnapshot after,
  required int cycles,
}) {
  final mod = report.mod(moduleKey);
  mod.passed++;
  final leaks = after.activeRecords
      .where((r) => !baseline.activeRecords.any((b) => b.id == r.id))
      .toList();
  if (leaks.isEmpty &&
      after.activeTimers <= baseline.activeTimers &&
      after.activePollers <= baseline.activePollers &&
      after.activeSse <= baseline.activeSse &&
      after.activeTrtc <= baseline.activeTrtc) {
    mod.passed++;
    return mod;
  }
  mod.failed++;
  mod.leaks = leaks.length;
  report.addBug(
    CfRootCauseAnalyzer.fromResourceLeaks(
      module: moduleKey,
      leaks: leaks.isNotEmpty ? leaks : after.activeRecords,
      hint: 'After $cycles enter/exit cycles, active resources did not return '
          'to baseline.',
    ),
  );
  return mod;
}
