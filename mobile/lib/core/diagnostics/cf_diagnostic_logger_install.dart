import 'dart:async';

import 'cf_diag.dart';
import 'cf_diagnostic_logger.dart';
import 'cf_monitors.dart';
import 'cf_resource_tracker.dart';

/// Mevcut CfDiag / ResourceTracker üzerine dosya logger bağlantısı.
abstract final class CfDiagnosticLoggerInstall {
  static var _installed = false;

  static Future<void> install() async {
    if (_installed) return;
    _installed = true;
    await CfDiagnosticLogger.loadPrefs();
    CfResourceTracker.onResourceEvent = CfDiagnosticLogger.onResourceEvent;
    CfDiag.addListener(_mirrorDiagEntry);
    if (CfDiagnosticLogger.active) {
      await CfDiagnosticLogger.startSession();
    }
    CfDiagnosticLogger.fileLoggingEnabled.addListener(_onFileToggle);
  }

  static void _onFileToggle() {
    if (CfDiagnosticLogger.fileLoggingEnabled.value) {
      CfMonitors.init();
      unawaited(CfDiagnosticLogger.startSession());
    }
  }

  static void _mirrorDiagEntry() {
    if (!CfDiagnosticLogger.active) return;
    final e = CfDiag.entries.isEmpty ? null : CfDiag.entries.last;
    if (e == null) return;
    if (e.level == CfLevel.error) {
      CfDiagnosticLogger.log(
        level: CfFileLogLevel.error,
        category: CfFileLogCategory.system,
        message: e.message,
        traceId: e.traceId,
        metadata: Map<String, Object?>.from(e.data),
      );
    }
  }
}
