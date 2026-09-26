import 'package:flutter_test/flutter_test.dart';

import 'package:canlifal_social/features/voice_hub/presentation/utils/voice_room_presence_self_sync.dart';

void main() {
  group('SelfPresenceTracker', () {
    test('stays out of the room until the backend acknowledges the join', () {
      final tracker = SelfPresenceTracker();
      expect(
        tracker.resolve(
          previous: true,
          backendJoinAcknowledged: false,
          listedInPresence: true,
          snapshotHasMembers: true,
        ),
        isFalse,
      );
    });

    test('being listed puts the user in the room immediately', () {
      final tracker = SelfPresenceTracker();
      expect(
        tracker.resolve(
          previous: false,
          backendJoinAcknowledged: true,
          listedInPresence: true,
          snapshotHasMembers: true,
        ),
        isTrue,
      );
    });

    test('an empty snapshot carries no information and keeps the state', () {
      final tracker = SelfPresenceTracker();
      expect(
        tracker.resolve(
          previous: true,
          backendJoinAcknowledged: true,
          listedInPresence: false,
          snapshotHasMembers: false,
        ),
        isTrue,
      );
      expect(tracker.missStreak, 0);
    });

    test('a single snapshot that omits the user does not drop the state', () {
      final tracker = SelfPresenceTracker();
      expect(
        tracker.resolve(
          previous: true,
          backendJoinAcknowledged: true,
          listedInPresence: false,
          snapshotHasMembers: true,
        ),
        isTrue,
        reason: 'tek yarış durumu "0 çevrimiçi" göstermemeli',
      );
    });

    test('two consecutive omissions are honoured as a real absence', () {
      final tracker = SelfPresenceTracker();
      for (var i = 0; i < 1; i++) {
        tracker.resolve(
          previous: true,
          backendJoinAcknowledged: true,
          listedInPresence: false,
          snapshotHasMembers: true,
        );
      }
      expect(
        tracker.resolve(
          previous: true,
          backendJoinAcknowledged: true,
          listedInPresence: false,
          snapshotHasMembers: true,
        ),
        isFalse,
      );
    });

    test('being listed again clears the miss streak', () {
      final tracker = SelfPresenceTracker();
      tracker.resolve(
        previous: true,
        backendJoinAcknowledged: true,
        listedInPresence: false,
        snapshotHasMembers: true,
      );
      tracker.resolve(
        previous: true,
        backendJoinAcknowledged: true,
        listedInPresence: true,
        snapshotHasMembers: true,
      );
      expect(tracker.missStreak, 0);
      expect(
        tracker.resolve(
          previous: true,
          backendJoinAcknowledged: true,
          listedInPresence: false,
          snapshotHasMembers: true,
        ),
        isTrue,
      );
    });

    test('reset clears the streak on re-entry', () {
      final tracker = SelfPresenceTracker();
      tracker.resolve(
        previous: true,
        backendJoinAcknowledged: true,
        listedInPresence: false,
        snapshotHasMembers: true,
      );
      tracker.reset();
      expect(tracker.missStreak, 0);
    });
  });

  group('resolveRejoinSeatIndex', () {
    test('prefers the seat the user currently holds', () {
      expect(
        resolveRejoinSeatIndex(
          currentSeatIndex: 4,
          lastConfirmedSeatIndex: 2,
        ),
        4,
      );
    });

    test('falls back to the last confirmed seat after a dropped heartbeat', () {
      expect(
        resolveRejoinSeatIndex(
          currentSeatIndex: null,
          lastConfirmedSeatIndex: 7,
        ),
        7,
      );
    });

    test('asks for no seat when the user was never seated', () {
      expect(
        resolveRejoinSeatIndex(
          currentSeatIndex: null,
          lastConfirmedSeatIndex: null,
        ),
        isNull,
      );
    });

    test('ignores non-positive seat indices', () {
      expect(
        resolveRejoinSeatIndex(currentSeatIndex: 0, lastConfirmedSeatIndex: 0),
        isNull,
      );
    });
  });
}
