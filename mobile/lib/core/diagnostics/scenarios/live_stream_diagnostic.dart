library;

import '../cf_resource_tracker.dart';
import 'diagnostic_common.dart';

abstract final class LiveStreamDiagnosticFlow {
  static const steps = <String>[
    'open_live_list',
    'open_stream',
    'viewer_trtc_join',
    'sse_chat',
    'heartbeat',
    'gift',
    'pk',
    'leave_stream',
  ];
}

abstract final class LiveStreamDiagnosticChecks {
  static CfResourceSnapshot baseline() =>
      CfResourceTracker.snapshot(module: 'live_stream');
}
