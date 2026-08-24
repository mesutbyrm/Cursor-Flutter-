import 'package:canlifal_social/features/voice_hub/domain/entities/chat_room_presence.dart';
import 'package:canlifal_social/features/voice_hub/presentation/providers/chat_room_providers.dart';
import 'package:canlifal_social/features/voice_hub/presentation/utils/voice_seat_snapshot.dart';
import 'package:canlifal_social/features/live/domain/entities/voice_room_entity.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('VoiceSeatSnapshot', () {
    final room = VoiceRoomEntity(
      id: 'room-1',
      slug: 'room-1',
      nameTr: 'Test',
      ownerId: 'owner-1',
      seatCount: 12,
    );

    VoiceRoomLiveState liveWith(List<ChatRoomPresence> presence) {
      return VoiceRoomLiveState(
        presence: presence,
        loading: false,
        backendSyncReady: true,
      );
    }

    test('fromLive returns empty seat when no occupant', () {
      final snap = VoiceSeatSnapshot.fromLive(
        room: room,
        live: liveWith(const []),
        seatIndex: 3,
      );
      expect(snap.user, isNull);
      expect(snap.locked, isFalse);
    });

    test('fromLive tracks occupant mic and speaking fields', () {
      const user = ChatRoomPresence(
        id: 'u1',
        name: 'Alice',
        seatIndex: 3,
        isSpeaking: true,
        micOn: false,
      );
      final snap = VoiceSeatSnapshot.fromLive(
        room: room,
        live: liveWith(const [user]),
        seatIndex: 3,
      );
      expect(snap.user?.id, 'u1');
      expect(snap.micOpen, isFalse);
      expect(snap.isSpeaking(), isTrue);
      expect(snap.isSpeaking(extraSpeakingIds: {'other'}), isTrue);
    });

    test('equality ignores unrelated seat changes', () {
      const seat3 = ChatRoomPresence(
        id: 'u3',
        name: 'Seat3',
        seatIndex: 3,
      );
      const seat5 = ChatRoomPresence(
        id: 'u5',
        name: 'Seat5',
        seatIndex: 5,
      );
      final before = VoiceSeatSnapshot.fromLive(
        room: room,
        live: liveWith(const [seat3]),
        seatIndex: 3,
      );
      final after = VoiceSeatSnapshot.fromLive(
        room: room,
        live: liveWith(const [seat3, seat5]),
        seatIndex: 3,
      );
      expect(before, equals(after));
    });

    test('equality detects seat occupant change', () {
      const a = ChatRoomPresence(id: 'u1', name: 'A', seatIndex: 2);
      const b = ChatRoomPresence(id: 'u2', name: 'B', seatIndex: 2);
      final snapA = VoiceSeatSnapshot.fromLive(
        room: room,
        live: liveWith(const [a]),
        seatIndex: 2,
      );
      final snapB = VoiceSeatSnapshot.fromLive(
        room: room,
        live: liveWith(const [b]),
        seatIndex: 2,
      );
      expect(snapA, isNot(equals(snapB)));
    });
  });
}
