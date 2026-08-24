import 'package:canlifal_social/features/live/domain/entities/voice_room_entity.dart';
import 'package:canlifal_social/features/live/presentation/providers/voice_rooms_list_notifier.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('patchVoiceRoomsInList updates matching room', () {
    const rooms = [
      VoiceRoomEntity(
        id: 'room_cuid_abcdefghij',
        slug: 'my-room',
        nameTr: 'Test',
        isLocked: false,
        seatCount: 8,
        maxUsers: 15,
      ),
    ];

    final next = patchVoiceRoomsInList(
      rooms,
      'room_cuid_abcdefghij',
      (r) => r.copyWith(isLocked: true, seatCount: 12, maxUsers: 50),
    );

    expect(next.single.isLocked, true);
    expect(next.single.seatCount, 12);
    expect(next.single.maxUsers, 50);
  });
}
