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
  });
}
