import 'cf_resource_tracker.dart';

enum CfBugSeverity { low, medium, high, critical }

class CfBugReport {
  CfBugReport({
    required this.id,
    required this.module,
    required this.category,
    required this.severity,
    required this.detectedAt,
    required this.evidence,
    required this.rootCause,
    this.file,
    this.line,
    this.recommendedFix,
  });

  final String id;
  final String module;
  final String category;
  final CfBugSeverity severity;
  final DateTime detectedAt;
  final String evidence;
  final String rootCause;
  final String? file;
  final int? line;
  final String? recommendedFix;

  String toMarkdown() {
    final sev = severity.name.toUpperCase();
    final ts = detectedAt.toIso8601String();
    final loc = file != null
        ? 'File:\n$file${line != null ? '\nLine:\n$line' : ''}\n\n'
        : '';
    final fix = recommendedFix != null
        ? 'Recommended Fix:\n$recommendedFix\n'
        : '';
    return '''
BUG #$id

Module:
$module

Category:
$category

Severity:
$sev

Detected:
$ts

Evidence:

$evidence

Root Cause:
$rootCause

$loc$fix''';
  }
}

/// Test FAIL sonrası otomatik kök neden taslağı.
abstract final class CfRootCauseAnalyzer {
  static var _bugSeq = 0;

  static CfBugReport fromResourceLeaks({
    required String module,
    required List<CfResourceRecord> leaks,
    String? hint,
  }) {
    _bugSeq++;
    final id = _bugSeq.toString().padLeft(3, '0');
    final byKind = <CfResourceKind, int>{};
    for (final r in leaks) {
      byKind[r.kind] = (byKind[r.kind] ?? 0) + 1;
    }
    final evidence = StringBuffer();
    for (final e in byKind.entries) {
      final created =
          leaks.where((r) => r.kind == e.key).map((r) => r.label).join(', ');
      evidence.writeln('Active ${e.key.name}: ${e.value} ($created)');
    }
    final snap = CfResourceTracker.snapshot(module: module);
    evidence.writeln(
      'Created total: ${snap.createdTotal}, disposed: ${snap.disposedTotal}',
    );
    final category = _leakCategory(byKind);
    return CfBugReport(
      id: id,
      module: module,
      category: category,
      severity: CfBugSeverity.high,
      detectedAt: DateTime.now(),
      evidence: evidence.toString().trim(),
      rootCause: hint ??
          'Screen/module exited but tracked resources remain active '
          '(timer/poller/SSE/TRTC not disposed).',
      recommendedFix:
          'Ensure cancel/dispose in controller dispose(), leave pipeline, '
          'and SSE/TRTC release on navigation pop.',
    );
  }

  static CfBugReport fromDuplicateRequests({
    required String module,
    required int expected,
    required int actual,
    String? endpoint,
  }) {
    _bugSeq++;
    final id = _bugSeq.toString().padLeft(3, '0');
    return CfBugReport(
      id: id,
      module: module,
      category: 'Request Duplicate',
      severity: CfBugSeverity.high,
      detectedAt: DateTime.now(),
      evidence: 'Expected $expected request(s), observed $actual'
          '${endpoint != null ? ' for $endpoint' : ''}.',
      rootCause:
          'Missing single-flight or debounce on user action / state rebuild.',
      recommendedFix:
          'Use CfSingleFlight or guard with in-flight flag; disable button while pending.',
    );
  }

  static CfBugReport fromUiFreeze({
    required String module,
    required Duration duration,
    required String lastAction,
    CfResourceSnapshot? resources,
  }) {
    _bugSeq++;
    final id = _bugSeq.toString().padLeft(3, '0');
    final res = resources ?? CfResourceTracker.snapshot();
    return CfBugReport(
      id: id,
      module: module,
      category: 'UI Freeze',
      severity: duration.inMilliseconds >= 1000
          ? CfBugSeverity.critical
          : CfBugSeverity.medium,
      detectedAt: DateTime.now(),
      evidence: '''
UI FREEZE

Screen:
$module

Duration:
${duration.inMilliseconds} ms

Last Action:
$lastAction

Timer:
${res.activeTimers}

Polling:
${res.activePollers}

SSE:
${res.activeSse}

TRTC:
${res.activeTrtc}

Request:
${res.activeRequests}
''',
      rootCause:
          'Main isolate blocked (sync work, await chain, or heavy rebuild).',
      recommendedFix:
          'Move work off UI thread; reduce rebuild scope; fix pending API on main isolate.',
    );
  }

  static String _leakCategory(Map<CfResourceKind, int> byKind) {
    if ((byKind[CfResourceKind.timer] ?? 0) > 0) return 'Timer Leak';
    if ((byKind[CfResourceKind.poller] ?? 0) > 0) return 'Polling Leak';
    if ((byKind[CfResourceKind.sse] ?? 0) > 0) return 'SSE Leak';
    if ((byKind[CfResourceKind.trtc] ?? 0) > 0) return 'TRTC Leak';
    if ((byKind[CfResourceKind.request] ?? 0) > 0) return 'Request Leak';
    return 'Resource Leak';
  }

  @visibleForTesting
  static void resetForTest() => _bugSeq = 0;
}
