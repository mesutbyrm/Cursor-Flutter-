import 'package:flutter/foundation.dart';

import 'package:canlifal_social/core/network/live_debug_log.dart';

/// Falcı 1:1 TRTC oturumu — cihaz tanılama özeti.
class PsychicRtcSessionReport {
  PsychicRtcSessionReport._();

  static final List<Map<String, dynamic>> _events = [];

  static void record(String phase, Map<String, dynamic> fields) {
    final entry = {
      'ts': DateTime.now().toIso8601String(),
      'phase': phase,
      ...fields,
    };
    _events.add(entry);
    if (_events.length > 80) {
      _events.removeAt(0);
    }
    LiveDebugLog.log('psychic.rtc.report.$phase', fields);
  }

  static List<Map<String, dynamic>> snapshot() =>
      List<Map<String, dynamic>>.from(_events);

  static void dump({String tag = 'psychic_rtc'}) {
    if (!kDebugMode) return;
    debugPrint('── $tag RTC report (${_events.length} events) ──');
    for (final e in _events) {
      debugPrint('  ${e['ts']} ${e['phase']}: $e');
    }
    debugPrint('── end $tag ──');
  }

  static void clear() => _events.clear();
}
