import 'package:canlifal_social/features/live/domain/entities/voice_room_entity.dart';
import 'package:canlifal_social/features/voice_hub/domain/entities/chat_room_presence.dart';
import 'package:canlifal_social/features/voice_hub/presentation/providers/chat_room_providers.dart';
import 'package:canlifal_social/features/voice_hub/presentation/providers/voice_room_ui_provider.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('VoiceRoomLiveState.onlineCountFor', () {
    const room = VoiceRoomEntity(
      id: 'r1',
      slug: 'r1',
      nameTr: 'Test',
      onlineCount: 42,
    );

    test('prefers backend hub count over room card count', () {
      const state = VoiceRoomLiveState(
        loading: false,
        hubOnlineCount: 99,
        selfInRoom: true,
      );
      expect(state.onlineCountFor(room), 99);
    });

    test('uses presence length when larger than hub count', () {
      final state = VoiceRoomLiveState(
        loading: false,
        hubOnlineCount: 2,
        presence: [
          const ChatRoomPresence(id: 'a', name: 'A'),
          const ChatRoomPresence(id: 'b', name: 'B'),
          const ChatRoomPresence(id: 'c', name: 'C'),
        ],
      );
      expect(state.onlineCountFor(room), 3);
    });
  });

  group('VoiceRoomUiState output gate', () {
    test('effectiveMusicMuted when headphones off', () {
      const state = VoiceRoomUiState(
        backgroundMusicEnabled: true,
        headphonesOn: false,
      );
      expect(state.effectiveMusicMuted, isTrue);
      expect(state.roomOutputEnabled, isFalse);
    });

    test('music plays only when both enabled', () {
      const state = VoiceRoomUiState(
        backgroundMusicEnabled: true,
        headphonesOn: true,
      );
      expect(state.effectiveMusicMuted, isFalse);
    });
  });
}
