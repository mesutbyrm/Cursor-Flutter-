import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:canlifal_social/core/diagnostics/cf_diagnostic_report.dart';
import 'package:canlifal_social/core/diagnostics/cf_monitors.dart';
import 'package:canlifal_social/core/diagnostics/cf_diag.dart';

/// Gerçek cihaz + production API zorunluluğu — mock PASS yok.
class DiagnosticHarness {
  DiagnosticHarness({CfDiagnosticReport? report})
      : report = report ??
            CfDiagnosticReport(
              startedAt: DateTime.now(),
              kind: CfDiagnosticRunKind.integrationRealDevice,
            );

  final CfDiagnosticReport report;
  final IntegrationTestWidgetsFlutterBinding binding =
      IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  static const realDeviceFlag = bool.fromEnvironment(
    'CANLIFAL_REAL_DEVICE_TEST',
    defaultValue: false,
  );

  static const apiBase = String.fromEnvironment(
    'CANLIFAL_API_BASE',
    defaultValue: 'https://canlifal.com',
  );

  /// Acceptance test hesapları — CI secret veya yerel export.
  static String env(String key, {String defaultValue = ''}) {
    final fromEnv = Platform.environment[key];
    if (fromEnv != null && fromEnv.trim().isNotEmpty) return fromEnv.trim();
    return defaultValue;
  }

  bool get hasCredentials {
    final email = env('ACCEPTANCE_USER_EMAIL',
        defaultValue: 'cursor.test.1786235468@mailinator.com');
    final pass = env('ACCEPTANCE_USER_PASSWORD',
        defaultValue: 'CursorTest!1786235468');
    return email.isNotEmpty && pass.isNotEmpty;
  }

  bool get isAndroidDevice =>
      !kIsWeb && Platform.isAndroid && binding.platformDispatcher.views.isNotEmpty;

  /// Gerçek cihaz testi koşulabilir mi?
  bool get canRunRealDevice =>
      realDeviceFlag && isAndroidDevice && hasCredentials;

  String get skipReason {
    if (!realDeviceFlag) {
      return 'TEST NOT RUN — set CANLIFAL_REAL_DEVICE_TEST=true';
    }
    if (!isAndroidDevice) {
      return 'TEST NOT RUN — no Android device (flutter devices)';
    }
    if (!hasCredentials) {
      return 'TEST NOT RUN — missing ACCEPTANCE_USER_EMAIL/PASSWORD';
    }
    return '';
  }

  void markModuleNotRun(String moduleKey, {String? note}) {
    final m = report.mod(moduleKey);
    m.skipped++;
    report.modules[moduleKey] = CfModuleResult(
      module: moduleKey,
      skipped: 1,
      notRun: true,
      notes: note ?? skipReason,
    );
  }

  void startMonitors() {
    CfDiag.verbose.value = true;
    CfFrameMonitor.start();
    CfFreezeWatchdog.start();
  }

  void stopMonitors() {
    CfFrameMonitor.stop();
    CfFreezeWatchdog.stop();
  }

  Future<void> finalizeAndPrint() async {
    report.finalizeOverall();
    if (!canRunRealDevice) {
      report.overallStatus = 'NOT RUN';
    }
    // Host script stdout'tan yakalar.
    debugPrint('===CANLIFAL_DIAG_JSON_START===');
    debugPrint(report.summaryMarkdown());
    debugPrint('===CANLIFAL_DIAG_JSON_END===');
  }
}

/// integration_test skip — PASS yazmaz.
void skipRealDeviceUnless(DiagnosticHarness harness) {
  if (harness.canRunRealDevice) return;
  markTestSkipped(harness.skipReason);
}
