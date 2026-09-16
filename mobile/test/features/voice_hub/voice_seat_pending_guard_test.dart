import 'package:flutter_test/flutter_test.dart';

import 'package:canlifal_social/features/voice_hub/domain/entities/chat_room_presence.dart';
import 'package:canlifal_social/features/voice_hub/domain/voice_seat_pending_guard.dart';

void main() {
  group('guardPresenceAgainstPendingSeatActions', () {
    test('pending take keeps previous seat when snapshot clears seatIndex', () {
      const userId = 'host-1';
      final previous = [
        const ChatRoomPresence(id: userId, name: 'Host', seatIndex: 2),
      ];
      final incoming = [
        const ChatRoomPresence(id: userId, name: 'Host', seatIndex: null),
      ];
      final pending = {
        userId: VoiceSeatPendingAction(
          userId: userId,
          kind: VoiceSeatPendingKind.take,
          seatIndex: 2,
          expiresAt: DateTime.now().add(const Duration(seconds: 5)),
        ),
      };
      final out = guardPresenceAgainstPendingSeatActions(
        merged: incoming,
        previous: previous,
        pendingByUser: pending,
      );
      expect(out.single.seatIndex, 2);
    });

    test('pending leave forces seatless when snapshot still seated', () {
      const userId = 'mod-1';
      final previous = [
        const ChatRoomPresence(id: userId, name: 'Mod', seatIndex: 1),
      ];
      final incoming = [
        const ChatRoomPresence(id: userId, name: 'Mod', seatIndex: 3),
      ];
      final pending = {
        userId: VoiceSeatPendingAction(
          userId: userId,
          kind: VoiceSeatPendingKind.leave,
          expiresAt: DateTime.now().add(const Duration(seconds: 5)),
        ),
      };
      final out = guardPresenceAgainstPendingSeatActions(
        merged: incoming,
        previous: previous,
        pendingByUser: pending,
      );
      expect(out.single.seatIndex, isNull);
    });

    test('other users are not affected by pending guard', () {
      const seated = 'u-a';
      const other = 'u-b';
      final previous = [
        const ChatRoomPresence(id: seated, name: 'A', seatIndex: 1),
        const ChatRoomPresence(id: other, name: 'B', seatIndex: null),
      ];
      final incoming = [
        const ChatRoomPresence(id: seated, name: 'A', seatIndex: null),
        const ChatRoomPresence(id: other, name: 'B', seatIndex: 2),
      ];
      final pending = {
        seated: VoiceSeatPendingAction(
          userId: seated,
          kind: VoiceSeatPendingKind.take,
          seatIndex: 1,
          expiresAt: DateTime.now().add(const Duration(seconds: 5)),
        ),
      };
      final out = guardPresenceAgainstPendingSeatActions(
        merged: incoming,
        previous: previous,
        pendingByUser: pending,
      );
      expect(out.firstWhere((p) => p.id == seated).seatIndex, 1);
      expect(out.firstWhere((p) => p.id == other).seatIndex, 2);
    });
  });
}
