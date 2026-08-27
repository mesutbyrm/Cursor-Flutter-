import 'package:flutter_test/flutter_test.dart';

import 'package:canlifal_social/features/voice_hub/domain/entities/chat_room_presence.dart';
import 'package:canlifal_social/features/voice_hub/domain/presence_canonical.dart';
import 'package:canlifal_social/features/voice_hub/domain/room_event_scope.dart';

void main() {
  group('dedupePresencesById', () {
    test('merges duplicate userId entries', () {
      final list = [
        const ChatRoomPresence(id: 'u1', name: 'Ali', seatIndex: 1),
        const ChatRoomPresence(id: 'u1', name: 'Ali Y.', seatIndex: 1),
      ];
      final out = dedupePresencesById(list);
      expect(out.length, 1);
      expect(out.first.id, 'u1');
    });

    test('does not keep sticky isSpeaking when server clears it', () {
      final speaking = dedupePresencesById([
        const ChatRoomPresence(id: 'u1', name: 'Ali', isSpeaking: false),
        const ChatRoomPresence(id: 'u1', name: 'Ali', isSpeaking: true),
      ]);
      expect(speaking.single.isSpeaking, isTrue);

      final cleared = dedupePresencesById([
        speaking.single,
        const ChatRoomPresence(id: 'u1', name: 'Ali', isSpeaking: false),
      ]);
      expect(cleared.single.isSpeaking, isFalse);
    });

    test('reconcilePresenceWithServer uses server list', () {
      final local = [
        const ChatRoomPresence(id: 'a', name: 'A'),
        const ChatRoomPresence(id: 'b', name: 'B'),
        const ChatRoomPresence(id: 'c', name: 'C'),
      ];
      final server = [
        const ChatRoomPresence(id: 'a', name: 'A'),
        const ChatRoomPresence(id: 'b', name: 'B'),
      ];
      final out = reconcilePresenceWithServer(local: local, server: server);
      expect(out.map((e) => e.id).toList(), ['a', 'b']);
    });

    test('empty server snapshot replaces local (no ghosts)', () {
      final local = [
        const ChatRoomPresence(id: 'a', name: 'A'),
        const ChatRoomPresence(id: 'b', name: 'B'),
      ];
      final out = reconcilePresenceWithServer(local: local, server: const []);
      expect(out, isEmpty);
    });
  });

  group('canonicalPresenceIdFromJson', () {
    test('prefers userId over id', () {
      expect(
        canonicalPresenceIdFromJson({'id': 'x', 'userId': 'real-u1'}),
        'real-u1',
      );
    });
  });

  group('roomEventMatchesActiveRoom', () {
    test('accepts matching roomId', () {
      expect(
        roomEventMatchesActiveRoom({'roomId': 'room-abc'}, 'room-abc'),
        isTrue,
      );
    });

    test('rejects foreign roomId', () {
      expect(
        roomEventMatchesActiveRoom({'roomId': 'room-other'}, 'room-abc'),
        isFalse,
      );
    });

    test('accepts empty roomId in payload for backward compat', () {
      expect(roomEventMatchesActiveRoom({}, 'room-abc'), isTrue);
    });
  });

  group('resolveRoomOnlineCount', () {
    test('prefers backend count', () {
      expect(
        resolveRoomOnlineCount(backendCount: 2, participantCount: 5),
        2,
      );
    });

    test('falls back to participant count', () {
      expect(
        resolveRoomOnlineCount(backendCount: null, participantCount: 3),
        3,
      );
    });
  });

  group('replacePresenceSnapshot', () {
    test('JOIN C then LEAVE B leaves A,C — B does not resurrect', () {
      const a = ChatRoomPresence(id: 'a', name: 'A');
      const b = ChatRoomPresence(id: 'b', name: 'B');
      const c = ChatRoomPresence(id: 'c', name: 'C');
      var state = replacePresenceSnapshot(
        previous: const [],
        incoming: [a, b],
      );
      expect(state.map((e) => e.id), ['a', 'b']);

      state = replacePresenceSnapshot(previous: state, incoming: [a, b, c]);
      expect(state.map((e) => e.id), ['a', 'b', 'c']);

      state = replacePresenceSnapshot(previous: state, incoming: [a, c]);
      expect(state.map((e) => e.id), ['a', 'c']);

      state = replacePresenceSnapshot(previous: state, incoming: [a, c]);
      expect(state.map((e) => e.id), ['a', 'c']);
    });

    test('does not copy previous seatIndex when server clears it', () {
      final previous = [
        const ChatRoomPresence(id: 'u1', name: 'Ali', seatIndex: 3),
      ];
      final incoming = [
        const ChatRoomPresence(id: 'u1', name: '', seatIndex: null),
      ];
      final out = replacePresenceSnapshot(
        previous: previous,
        incoming: incoming,
      );
      expect(out.single.name, 'Ali');
      expect(out.single.seatIndex, isNull);
    });

    test('room B snapshot does not keep room A members', () {
      final roomA = [
        const ChatRoomPresence(id: 'x', name: 'X'),
        const ChatRoomPresence(id: 'y', name: 'Y'),
      ];
      final roomB = [
        const ChatRoomPresence(id: 'z', name: 'Z'),
      ];
      final switched = replacePresenceSnapshot(
        previous: roomA,
        incoming: roomB,
      );
      expect(switched.map((e) => e.id), ['z']);
      expect(switched.any((e) => e.id == 'x'), isFalse);
    });
  });

  group('shouldApplyCanonicalSeats', () {
    test('ignores empty fetch payload', () {
      expect(shouldApplyCanonicalSeats(const []), isFalse);
    });

    test('applies occupied-empty slot map', () {
      expect(shouldApplyCanonicalSeats([1, 2, 3]), isTrue);
    });
  });

  group('isPresenceReplaceSource', () {
    test('sse and state_snapshot are replace', () {
      expect(isPresenceReplaceSource('sse'), isTrue);
      expect(isPresenceReplaceSource('state_snapshot'), isTrue);
      expect(isPresenceReplaceSource('poll'), isFalse);
    });
  });
}
