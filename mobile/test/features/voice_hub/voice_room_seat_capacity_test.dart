import 'package:canlifal_social/features/live/domain/entities/voice_room_entity.dart';
import 'package:canlifal_social/features/voice_hub/domain/entities/chat_room_presence.dart';
import 'package:canlifal_social/features/voice_hub/domain/entities/voice_room_seat_slot.dart';
import 'package:canlifal_social/features/voice_hub/presentation/utils/voice_room_seat_capacity.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final room = VoiceRoomEntity(
    id: 'r1',
    slug: 'test',
    nameTr: 'Test',
    seatCount: 5,
  );

  ChatRoomPresence guest(String id, int seat) => ChatRoomPresence(
        id: id,
        name: id,
        seatIndex: seat,
      );

  group('progressiveVisibleGuestSeatIndices', () {
    test('seatCount 1 shows no guest slots', () {
      final visible = progressiveVisibleGuestSeatIndices(
        room: room.copyWith(seatCount: 1),
        presence: const [],
        configuredSeatCount: 1,
      );
      expect(visible, isEmpty);
    });

    test('seatCount 5 shows one trailing plus when empty', () {
      final visible = progressiveVisibleGuestSeatIndices(
        room: room,
        presence: const [],
        configuredSeatCount: 5,
      );
      expect(visible, [2]);
    });

    test('progressive plus advances after guest sits', () {
      final visible = progressiveVisibleGuestSeatIndices(
        room: room,
        presence: [guest('u1', 2)],
        configuredSeatCount: 5,
      );
      expect(visible, [2, 3]);
    });

    test('seatCount 15 stops showing plus when layout is full', () {
      final presence = <ChatRoomPresence>[
        for (var i = 2; i <= 11; i++) guest('u$i', i),
      ];
      final visible = progressiveVisibleGuestSeatIndices(
        room: room.copyWith(seatCount: 15),
        presence: presence,
        configuredSeatCount: 15,
      );
      expect(visible, isNot(contains(12)));
      expect(visible.length, 10);
    });

    test('locked backend seat is skipped for plus slot', () {
      final visible = progressiveVisibleGuestSeatIndices(
        room: room,
        presence: const [],
        seatSlots: const [
          VoiceRoomSeatSlot(index: 2, isLocked: true),
          VoiceRoomSeatSlot(index: 3),
        ],
        configuredSeatCount: 5,
      );
      expect(visible, [3]);
    });
  });
}
