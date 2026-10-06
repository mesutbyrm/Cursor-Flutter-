library;

import '../cf_resource_tracker.dart';
import 'diagnostic_common.dart';

abstract final class VoiceRoomDiagnosticFlow {
  static const steps = <String>[
    'open_voice_list',
    'enter_room',
    'take_seat',
    'speak',
    'leave_seat',
    'mute_unmute',
    'leave_room',
    'enter_other_room',
  ];
}

abstract final class VoiceRoomDiagnosticChecks {
  static CfResourceSnapshot baseline() =>
      CfResourceTracker.snapshot(module: 'voice_room');

  static const leaveMustClear = <String>[
    'trtc_leave',
    'mic_off',
    'sse_close',
    'heartbeat_stop',
    'timer_stop',
    'polling_stop',
  ];
}
