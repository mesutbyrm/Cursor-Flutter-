import 'package:canlifal_social/core/room/room_event_scope.dart';
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

    test('falls back to presence length when hub unset after sync', () {
      const state = VoiceRoomLiveState(
        loading: false,
        backendSyncReady: true,
        presence: [
          ChatRoomPresence(id: 'a', name: 'A'),
          ChatRoomPresence(id: 'b', name: 'B'),
        ],
      );
      expect(state.onlineCountFor(room), 2);
    });

    test('falls back to room card when hub unset before sync', () {
      const state = VoiceRoomLiveState(loading: false);
      expect(state.onlineCountFor(room), 42);
    });

    test('after sync empty presence is 0 not catalog count', () {
      const state = VoiceRoomLiveState(
        loading: false,
        backendSyncReady: true,
      );
      expect(state.onlineCountFor(room), 0);
    });

    test('in-room uses presence length when hub unset', () {
      const state = VoiceRoomLiveState(
        loading: false,
        selfInRoom: true,
        presence: [
          ChatRoomPresence(id: 'a', name: 'A'),
        ],
      );
      expect(state.onlineCountFor(room), 1);
    });
  });

  group('sessionKeyMatchesActiveRoom', () {
    test('matches slug and cuid aliases', () {
      expect(
        sessionKeyMatchesActiveRoom(
          sessionKey: 'my-room-slug',
          activeRoomKey: 'cm123456789012345678',
          roomAliases: {'my-room-slug', 'cm123456789012345678'},
        ),
        isTrue,
      );
    });

    test('rejects unrelated room keys', () {
      expect(
        sessionKeyMatchesActiveRoom(
          sessionKey: 'room-a',
          activeRoomKey: 'room-b',
          roomAliases: {'room-b'},
        ),
        isFalse,
      );
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
