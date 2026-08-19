import 'package:canlifal_social/features/voice_hub/presentation/utils/voice_room_nav_paths.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('voiceRoomLiveKeyFromPath extracts room id', () {
    expect(voiceRoomLiveKeyFromPath('/voice-room/cmoohrbr'), 'cmoohrbr');
    expect(voiceRoomLiveKeyFromPath('voice-room/abc123'), 'abc123');
    expect(voiceRoomLiveKeyFromPath('/voice-room/cmoohrbr/pk'), 'cmoohrbr');
    expect(voiceRoomLiveKeyFromPath('/feed'), isNull);
    expect(voiceRoomLiveKeyFromPath('/voice-room/'), isNull);
  });

  test('isVoiceRoomNavigationPath', () {
    expect(isVoiceRoomNavigationPath('/voice-room/x'), isTrue);
    expect(isVoiceRoomNavigationPath('/live/1'), isFalse);
  });
}
