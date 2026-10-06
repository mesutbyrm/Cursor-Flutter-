import 'package:flutter/foundation.dart';

import 'cf_diagnostic_logger.dart';

/// Canlı fal / yayın / sesli oda oturum durumu (stale event tespiti).
abstract final class CfDiagnosticSessionMonitor {
  static String? _activeKey;
  static String? _activeType;

  static void transition({
    required String type,
    required String sessionKey,
    required String state,
    Map<String, Object?> metadata = const {},
  }) {
    if (state == 'CREATE' || state == 'WAITING' || state == 'CONNECTING') {
      _activeKey = sessionKey;
      _activeType = type;
    }
    if (_activeKey != null &&
        _activeKey != sessionKey &&
        (state == 'CONNECTED' || state == 'ACTIVE' || state == 'EVENT')) {
      CfDiagnosticLogger.log(
        level: CfFileLogLevel.critical,
        category: CfFileLogCategory.session,
        message: 'STALE_SESSION_EVENT',
        metadata: {
          'activeSession': _activeKey,
          'activeType': _activeType,
          'incomingSession': sessionKey,
          'incomingType': type,
          'state': state,
          ...metadata,
        },
      );
    }
    if (state == 'ENDED' || state == 'ERROR') {
      if (_activeKey == sessionKey) {
        _activeKey = null;
        _activeType = null;
      }
    }
    CfDiagnosticLogger.sessionEvent(
      type: type,
      sessionKey: sessionKey,
      state: state,
      metadata: metadata,
    );
  }

  @visibleForTesting
  static void resetForTest() {
    _activeKey = null;
    _activeType = null;
  }
}
