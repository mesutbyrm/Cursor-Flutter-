import 'dart:io';

import 'package:archive/archive.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:share_plus/share_plus.dart';

import 'cf_diagnostic_logger.dart';
import 'cf_resource_tracker.dart';

/// ZIP + Share Sheet — Claude/Cursor için diagnostic paketi.
abstract final class CfDiagnosticExport {
  static Future<String?> exportAndShare() async {
    if (kIsWeb) return 'Web desteklenmiyor';
    await CfDiagnosticLogger.flush(force: true);
    final dir = CfDiagnosticLogger.sessionDirectory;
    if (dir == null || !dir.existsSync()) {
      return 'Aktif diagnostic oturumu yok — «Dosyaya kaydet» açın';
    }
    final stamp = DateTime.now();
    final name =
        'canlifal_diagnostic_${stamp.year}${stamp.month.toString().padLeft(2, '0')}${stamp.day.toString().padLeft(2, '0')}_'
        '${stamp.hour.toString().padLeft(2, '0')}${stamp.minute.toString().padLeft(2, '0')}${stamp.second.toString().padLeft(2, '0')}';
    final aiSummary = _buildAiSummary();
    await File(p.join(dir.path, 'AI_DEBUG_SUMMARY.md')).writeAsString(aiSummary);
    final zipPath = p.join(dir.parent.path, '$name.zip');
    final archive = Archive();
    for (final entity in dir.listSync(recursive: true)) {
      if (entity is! File) continue;
      final rel = p.relative(entity.path, from: dir.path);
      final bytes = await entity.readAsBytes();
      archive.addFile(ArchiveFile(rel, bytes.length, bytes));
    }
    final zipBytes = ZipEncoder().encode(archive);
    if (zipBytes == null) return 'ZIP oluşturulamadı';
    await File(zipPath).writeAsBytes(zipBytes);
    await Share.shareXFiles(
      [XFile(zipPath, mimeType: 'application/zip', name: '$name.zip')],
      subject: 'Canlifal diagnostic ${CfDiagnosticLogger.sessionId}',
      text: 'Canlifal diagnostic log — ${CfDiagnosticLogger.sessionId}',
    );
    return null;
  }

  static String _buildAiSummary() {
    final snap = CfResourceTracker.snapshot();
    final errs = CfDiagnosticLogger.errors;
    final critical = errs
        .where((e) =>
            e['level'] == 'critical' ||
            e['level'] == 'freeze' ||
            e['level'] == 'leak' ||
            e['level'] == 'duplicate')
        .toList();
    final b = StringBuffer()
      ..writeln('# Canlifal Diagnostic Summary')
      ..writeln()
      ..writeln('Session: ${CfDiagnosticLogger.sessionId}')
      ..writeln()
      ..writeln('## Critical Problems')
      ..writeln();
    if (critical.isEmpty) {
      b.writeln('(none in errors.json — search canlifal_diagnostic.log)');
    } else {
      for (var i = 0; i < critical.length; i++) {
        b.writeln('${i + 1}. ${critical[i]['message']} (${critical[i]['category']})');
      }
    }
    b
      ..writeln()
      ..writeln('## Resource snapshot')
      ..writeln('- timers: ${snap.activeTimers}')
      ..writeln('- pollers: ${snap.activePollers}')
      ..writeln('- sse: ${snap.activeSse}')
      ..writeln('- trtc: ${snap.activeTrtc}')
      ..writeln('- requests: ${snap.activeRequests}')
      ..writeln()
      ..writeln('## Last actions')
      ..writeln();
    for (final a in CfDiagnosticLogger.lastActions.reversed.take(25)) {
      b.writeln('- $a');
    }
    b
      ..writeln()
      ..writeln('## Recommended Investigation Files')
      ..writeln('- canlifal_diagnostic.log')
      ..writeln('- errors.json')
      ..writeln('- summary.json');
    return b.toString();
  }
}
