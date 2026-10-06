import 'package:canlifal_social/features/voice_hub/domain/voice_room_leave_pipeline_spec.dart';
import 'package:canlifal_social/features/voice_hub/presentation/coordinators/room_leave_coordinator.dart';
import 'package:flutter_test/flutter_test.dart';

/// Spec 14–17 — leave coordinator sırası sözleşme ile uyumlu simülasyon.
void main() {
  test('leave steps run in pipeline spec order', () async {
    final coordinator = RoomLeaveCoordinator();
    final ran = <String>[];

    await coordinator.leave(
      roomId: 'room-x',
      source: 'spec_test',
      steps: VoiceRoomLeavePipelineSpec.orderedStepIds
          .map(
            (id) => () async {
              ran.add(id);
            },
          )
          .toList(),
    );

    expect(ran, VoiceRoomLeavePipelineSpec.orderedStepIds);
    expect(ran.first, 'session_timers_and_leave_banner');
    expect(ran, contains('backend_live_leave_and_presence'));
    expect(ran, contains('hub_force_release_and_gift_pk_reset'));
  });

  test('pipeline spec documents minimum leave phases', () {
    expect(VoiceRoomLeavePipelineSpec.orderedStepIds.length, greaterThanOrEqualTo(5));
  });
}
