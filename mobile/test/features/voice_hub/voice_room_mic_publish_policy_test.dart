import 'package:canlifal_social/features/voice_hub/presentation/utils/voice_room_mic_publish_policy.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('VoiceRoomMicPublishPolicy', () {
    test('blocks publish without seat', () {
      expect(VoiceRoomMicPublishPolicy.mayPublishTrtcMic(null), isFalse);
      expect(VoiceRoomMicPublishPolicy.mayPublishTrtcMic(0), isFalse);
      expect(VoiceRoomMicPublishPolicy.mayPublishTrtcMic(-1), isFalse);
    });

    test('allows publish on valid seat index', () {
      expect(VoiceRoomMicPublishPolicy.mayPublishTrtcMic(1), isTrue);
      expect(VoiceRoomMicPublishPolicy.mayPublishTrtcMic(8), isTrue);
    });
  });
}
