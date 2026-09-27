import 'package:canlifal_social/features/live/domain/entities/voice_room_entity.dart';
import 'package:canlifal_social/features/voice_hub/domain/entities/chat_room_presence.dart';
import 'package:canlifal_social/features/voice_hub/domain/entities/voice_room_seat_slot.dart';
import 'package:canlifal_social/features/voice_hub/presentation/utils/voice_room_seat_layout.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('seatSlots keep occupant when presence drops seatIndex', () {
    const room = VoiceRoomEntity(
      id: 'room1',
      slug: 'room1',
      nameTr: 'Test',
      seatCount: 8,
    );
    const user = ChatRoomPresence(id: 'u1', name: 'Ali');
    const presence = [user];
    const slots = [
      VoiceRoomSeatSlot(index: 2, userId: 'u1', name: 'Ali'),
    ];

    final map = VoiceRoomSeatLayout(
      room: room,
      presence: presence,
      seatSlots: slots,
    ).build();

    expect(map[2]?.id, 'u1');
  });
}
