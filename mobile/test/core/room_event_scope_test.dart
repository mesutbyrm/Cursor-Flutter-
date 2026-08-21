import 'package:canlifal_social/core/room/room_event_scope.dart';
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
}
