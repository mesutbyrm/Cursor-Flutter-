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

    test('uses hubOnlineCount as sole source of truth', () {
      const state = VoiceRoomLiveState(
        loading: false,
        hubOnlineCount: 2,
        presence: [
          ChatRoomPresence(id: 'a', name: 'A'),
          ChatRoomPresence(id: 'b', name: 'B'),
          ChatRoomPresence(id: 'c', name: 'C'),
        ],
      );
      expect(state.onlineCountFor(room), 2);
    });

    test('prefers backend hub count over room card count', () {
      const state = VoiceRoomLiveState(
        loading: false,
        hubOnlineCount: 99,
        selfInRoom: true,
      );
      expect(state.onlineCountFor(room), 99);
    });

    test('falls back to room card when hub unset before sync', () {
      const state = VoiceRoomLiveState(loading: false);
      expect(state.onlineCountFor(room), 42);
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
