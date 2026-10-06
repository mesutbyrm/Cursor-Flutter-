/// Spec 14–17 — [VoiceRoomLiveController.leaveRoomSession] adım sırası (sözleşme).
///
/// Gerçek uygulama `chat_room_providers.dart` içindeki `RoomLeaveCoordinator.steps`
/// ile hizalı tutulmalıdır.
abstract final class VoiceRoomLeavePipelineSpec {
  static const orderedStepIds = <String>[
    'session_timers_and_leave_banner',
    'backend_live_leave_and_presence',
    'trtc_and_music_teardown',
    'local_session_and_sse_state_reset',
    'hub_force_release_and_gift_pk_reset',
    'dj_music_cleanup',
    'keep_alive_and_final_phase',
  ];
}
