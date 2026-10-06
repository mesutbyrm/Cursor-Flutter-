/// Canlı falcılar — gerçek cihaz diagnostic senaryoları.
library;

import '../cf_resource_tracker.dart';
import 'diagnostic_common.dart';

abstract final class LiveFortuneDiagnosticFlow {
  static const steps = <String>[
    'open_psychic_list',
    'open_psychic_detail',
    'send_request',
    'session_created',
    'waiting_screen',
    'trtc_join',
    'sse_connect',
    'heartbeat',
    'in_session',
    'end_session',
    'exit_screen',
  ];
}

abstract final class LiveFortuneDiagnosticChecks {
  static const timerLabels = [
    'tick',
    'ping',
    'signal_poll',
    'room_poll',
    'chat_poll',
    'remote_video_watchdog',
  ];

  static CfResourceSnapshot baseline() =>
      CfResourceTracker.snapshot(module: 'live_fortune');

  static bool singleSsePerSession(int activeSse, {int maxAllowed = 1}) =>
      activeSse <= maxAllowed;
}
