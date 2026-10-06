import 'dart:io';

import 'cf_root_cause.dart';
import 'cf_resource_tracker.dart';

enum CfDiagnosticRunKind {
  unit,
  integrationMock,
  integrationRealDevice,
}

class CfModuleResult {
  CfModuleResult({
    required this.module,
    this.passed = 0,
    this.failed = 0,
    this.skipped = 0,
    this.leaks = 0,
    this.freezes = 0,
    this.notRun = false,
    this.notes = '',
  });

  final String module;
  int passed;
  int failed;
  int skipped;
  int leaks;
  int freezes;
  final bool notRun;
  final String notes;

  bool get hasCriticalFailure => failed > 0 || leaks > 0 || freezes > 0;
}

class CfDiagnosticReport {
  CfDiagnosticReport({
    required this.startedAt,
    this.kind = CfDiagnosticRunKind.integrationRealDevice,
  }) : modules = {
          'LIVE FORTUNE': CfModuleResult(module: 'LIVE FORTUNE'),
          'LIVE STREAM': CfModuleResult(module: 'LIVE STREAM'),
          'VOICE ROOM': CfModuleResult(module: 'VOICE ROOM'),
          'GLOBAL APP': CfModuleResult(module: 'GLOBAL APP'),
        };

  final DateTime startedAt;
  final CfDiagnosticRunKind kind;
  final Map<String, CfModuleResult> modules;
  final List<CfBugReport> bugs = [];
  String overallStatus = 'NOT RUN';
  String deviceNote = '';
  DateTime? finishedAt;

  CfModuleResult mod(String key) => modules[key]!;

  void addBug(CfBugReport bug) => bugs.add(bug);

  void finalizeOverall() {
    finishedAt = DateTime.now();
    if (overallStatus == 'NOT RUN') return;
    for (final m in modules.values) {
      if (m.notRun) continue;
      if (m.hasCriticalFailure) {
        overallStatus = 'FAIL';
        return;
      }
    }
    if (modules.values.every((m) => m.notRun || (m.passed == 0 && m.failed == 0))) {
      overallStatus = 'NOT RUN';
      return;
    }
    overallStatus = bugs.isEmpty && !modules.values.any((m) => m.failed > 0)
        ? 'PASS'
        : 'FAIL';
  }

  String summaryMarkdown() {
    final totalPass =
        modules.values.fold(0, (a, m) => a + m.passed);
    final totalFail =
        modules.values.fold(0, (a, m) => a + m.failed);
    final totalSkip =
        modules.values.fold(0, (a, m) => a + m.skipped);
    final b = StringBuffer()
      ..writeln('# CANLIFAL Diagnostic Report')
      ..writeln()
      ..writeln('Started: ${startedAt.toIso8601String()}')
      ..writeln('Finished: ${finishedAt?.toIso8601String() ?? '-'}')
      ..writeln('Run kind: ${kind.name}')
      ..writeln('Device: ${deviceNote.isEmpty ? '(see REAL_DEVICE doc)' : deviceNote}')
      ..writeln()
      ..writeln('## OVERALL STATUS: **$overallStatus**')
      ..writeln()
      ..writeln('## Summary')
      ..writeln('- TOTAL PASSED: $totalPass')
      ..writeln('- TOTAL FAILED: $totalFail')
      ..writeln('- SKIPPED: $totalSkip')
      ..writeln('- BUGS FILE: ${bugs.length} findings')
      ..writeln()
      ..writeln('## Module results')
      ..writeln();
    for (final m in modules.values) {
      b.writeln('### ${m.module}');
      if (m.notRun) {
        b.writeln('- **TEST NOT RUN**${m.notes.isNotEmpty ? ': ${m.notes}' : ''}');
      } else {
        b.writeln('- PASS: ${m.passed}');
        b.writeln('- FAIL: ${m.failed}');
        b.writeln('- SKIPPED: ${m.skipped}');
        b.writeln('- LEAK: ${m.leaks}');
        b.writeln('- FREEZE: ${m.freezes}');
      }
      b.writeln();
    }
    final snap = CfResourceTracker.snapshot();
    b.writeln('## Resource snapshot (end)');
    b.writeln('- activeTimers: ${snap.activeTimers}');
    b.writeln('- activePollers: ${snap.activePollers}');
    b.writeln('- activeSse: ${snap.activeSse}');
    b.writeln('- activeTrtc: ${snap.activeTrtc}');
    b.writeln('- activeRequests: ${snap.activeRequests}');
    return b.toString();
  }

  String bugsMarkdown() {
    if (bugs.isEmpty) {
      return '# CANLIFAL Bugs Found\n\n(No bugs recorded — or tests NOT RUN on device.)\n';
    }
    return '# CANLIFAL Bugs Found\n\n${bugs.map((b) => b.toMarkdown()).join('\n---\n\n')}';
  }

  static Future<void> writeToRepoRoot(
    CfDiagnosticReport report, {
    String root = '/workspace',
  }) async {
    final dir = Directory(root);
    if (!dir.existsSync()) return;
    await File('$root/CANLIFAL_DIAGNOSTIC_REPORT.md')
        .writeAsString(report.summaryMarkdown());
    await File('$root/CANLIFAL_BUGS_FOUND.md')
        .writeAsString(report.bugsMarkdown());
  }
}
