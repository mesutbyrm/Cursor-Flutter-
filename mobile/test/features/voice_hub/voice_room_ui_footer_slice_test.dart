import 'package:canlifal_social/features/voice_hub/presentation/providers/voice_room_ui_provider.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('voiceRoomUiFooterSlice maps footer fields', () {
    const state = VoiceRoomUiState(
      headphonesOn: false,
      requestSpeakPending: true,
      backgroundMusicEnabled: false,
      chatNotificationSoundEnabled: false,
    );
    final slice = voiceRoomUiFooterSlice(state);
    expect(slice.headphonesOn, isFalse);
    expect(slice.requestSpeakPending, isTrue);
    expect(slice.effectiveMusicMuted, isTrue);
    expect(slice.chatNotificationSoundEnabled, isFalse);
  });

  test('voiceRoomUiFooterSlice record equality', () {
    const a = VoiceRoomUiState(headphonesOn: true, requestSpeakPending: false);
    const b = VoiceRoomUiState(headphonesOn: true, requestSpeakPending: false);
    expect(voiceRoomUiFooterSlice(a), voiceRoomUiFooterSlice(b));
  });
}
