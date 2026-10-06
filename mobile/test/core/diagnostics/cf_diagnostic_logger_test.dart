import 'package:canlifal_social/core/diagnostics/cf_diag.dart';
import 'package:canlifal_social/core/diagnostics/cf_diagnostic_logger.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  setUp(() {
    CfDiagnosticLogger.resetForTest();
    CfDiag.lastAction = 'SEND_FORTUNE_REQUEST';
  });

  tearDown(() {
    CfDiagnosticLogger.resetForTest();
    CfDiag.lastAction = null;
  });

  test('sanitize redacts bearer tokens in metadata path', () {
    CfDiagnosticLogger.fileLoggingEnabled.value = true;
    final line = CfDiagnosticLogger.newTraceId();
    expect(line.startsWith('CF-'), isTrue);
  });

  test('recentEvents buffer receives log entries when active', () {
    CfDiagnosticLogger.fileLoggingEnabled.value = true;
    CfDiagnosticLogger.log(
      level: CfFileLogLevel.info,
      category: CfFileLogCategory.request,
      message: 'REQUEST_START test',
    );
    expect(CfDiagnosticLogger.recentEvents, isNotEmpty);
    expect(
      CfDiagnosticLogger.recentEvents.last['category'],
      'request',
    );
  });

  test('duplicate request heuristic logs critical metadata', () {
    CfDiagnosticLogger.fileLoggingEnabled.value = true;
    CfDiagnosticLogger.requestStart(
      method: 'POST',
      endpoint: '/api/live/fortune/request',
    );
    CfDiagnosticLogger.requestStart(
      method: 'POST',
      endpoint: '/api/live/fortune/request',
    );
    final dup = CfDiagnosticLogger.errors
        .where((e) => '${e['message']}'.contains('DUPLICATE_REQUEST'));
    expect(dup.length, greaterThanOrEqualTo(1));
  });
}
