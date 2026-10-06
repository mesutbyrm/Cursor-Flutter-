import 'package:canlifal_social/features/voice_hub/domain/voice_room_background_recovery_spec.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Spec 20 — background recovery contract', () {
    test('background seat release duration', () {
      expect(
        VoiceRoomBackgroundRecoverySpec.backgroundSeatRelease.inSeconds,
        45,
      );
    });

    test('leave source constants are stable', () {
      expect(VoiceRoomBackgroundRecoverySpec.leaveSourceBackground, 'app_background');
      expect(VoiceRoomBackgroundRecoverySpec.leaveSourceDetached, 'app_detached');
    });

    test('SSE hub resume debounce is sub-second', () {
      expect(
        VoiceRoomBackgroundRecoverySpec.sseHubResumeDebounce.inMilliseconds,
        450,
      );
    });
  });
}
