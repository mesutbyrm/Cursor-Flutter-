import 'package:canlifal_social/core/room/room_event_scope.dart';
import 'package:canlifal_social/features/voice_hub/domain/room_event_scope.dart'
    as voice_scope;
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('roomEventMatchesActiveRoom', () {
    test('allows when no active room', () {
      expect(
        roomEventMatchesActiveRoom(
          eventRoomId: 'room-a',
          activeRoomId: null,
        ),
        isTrue,
      );
    });

    test('matches same room id', () {
      expect(
        roomEventMatchesActiveRoom(
          eventRoomId: 'room-a',
          activeRoomId: 'room-a',
        ),
        isTrue,
      );
    });

    test('rejects foreign room', () {
      expect(
        roomEventMatchesActiveRoom(
          eventRoomId: 'room-b',
          activeRoomId: 'room-a',
        ),
        isFalse,
      );
    });

    test('matches alternate alias keys', () {
      expect(
        roomEventMatchesActiveRoom(
          eventRoomId: 'slug-a',
          activeRoomId: 'room-a',
          alternateActiveKeys: ['slug-a'],
        ),
        isTrue,
      );
    });
  });

  group('sessionKeyMatchesActiveRoom', () {
    test('delegates to room scope', () {
      expect(
        sessionKeyMatchesActiveRoom(
          sessionKey: 'live-key',
          activeRoomKey: 'live-key',
        ),
        isTrue,
      );
    });
  });

  group('roomKeysEquivalent (VOICE-006 tek kural)', () {
    test('TRTC prefix forms match the raw id', () {
      expect(roomKeysEquivalent('voice_room_cm1', 'cm1'), isTrue);
      expect(roomKeysEquivalent('room_cm1', 'CM1'), isTrue);
      expect(roomKeysEquivalent('live-abc', 'abc'), isTrue);
    });

    test('no arbitrary suffix match', () {
      expect(roomKeysEquivalent('11', '1'), isFalse);
      expect(roomKeysEquivalent('room-a', 'a'), isFalse);
    });

    test('gift bridge and voice SSE filter agree', () {
      expect(
        roomEventMatchesActiveRoom(
          eventRoomId: 'voice_room_cm1',
          activeRoomId: 'cm1',
        ),
        isTrue,
      );
      expect(
        voice_scope.roomEventMatchesActiveRoom(
          {'roomId': 'voice_room_cm1'},
          'cm1',
        ),
        isTrue,
      );
      expect(
        voice_scope.roomEventMatchesActiveRoom({'roomId': '11'}, '1'),
        isFalse,
      );
    });
  });
}
