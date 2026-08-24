import 'package:canlifal_social/features/voice_hub/presentation/utils/voice_room_leave_flow.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('VoiceRoomLeaveFlow.shouldLeaveVoiceRoomRoute', () {
    test('matches voice room detail routes', () {
      expect(
        VoiceRoomLeaveFlow.shouldLeaveVoiceRoomRoute('/voice-room/abc'),
        isTrue,
      );
      expect(
        VoiceRoomLeaveFlow.shouldLeaveVoiceRoomRoute('/voice-room/abc/pk'),
        isTrue,
      );
    });

    test('does not match hub or unrelated routes', () {
      expect(
        VoiceRoomLeaveFlow.shouldLeaveVoiceRoomRoute('/voice-rooms'),
        isFalse,
      );
      expect(
        VoiceRoomLeaveFlow.shouldLeaveVoiceRoomRoute('/home'),
        isFalse,
      );
    });
  });
}
