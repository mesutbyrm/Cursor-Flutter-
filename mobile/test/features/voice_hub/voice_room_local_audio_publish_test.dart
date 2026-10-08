import 'package:canlifal_social/features/voice_hub/presentation/utils/voice_room_local_audio_publish.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('VoiceRoomLocalAudioPublish', () {
    test('blocks publish without slot seat even if mic intent on', () {
      final d = VoiceRoomLocalAudioPublish.evaluate(
        sessionActive: true,
        userId: 'u1',
        seatIndexFromSlots: null,
        micIntentOn: true,
      );
      expect(d.allowed, isFalse);
      expect(d.blockReason, 'not_on_seat');
    });

    test('blocks when session inactive', () {
      final d = VoiceRoomLocalAudioPublish.evaluate(
        sessionActive: false,
        userId: 'u1',
        seatIndexFromSlots: 2,
        micIntentOn: true,
      );
      expect(d.allowed, isFalse);
      expect(d.blockReason, 'no_session');
    });

    test('on seat but mic off does not publish', () {
      final d = VoiceRoomLocalAudioPublish.evaluate(
        sessionActive: true,
        userId: 'u1',
        seatIndexFromSlots: 3,
        micIntentOn: false,
      );
      expect(d.allowed, isFalse);
      expect(d.blockReason, 'mic_off');
    });

    test('on seat and mic on allows publish', () {
      final d = VoiceRoomLocalAudioPublish.evaluate(
        sessionActive: true,
        userId: 'u1',
        seatIndexFromSlots: 1,
        micIntentOn: true,
      );
      expect(d.allowed, isTrue);
    });
  });
}
