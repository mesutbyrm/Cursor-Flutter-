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

  test('patchVoiceRoomsInList updates isPkLive for matching room', () {
    const rooms = [
      VoiceRoomEntity(id: 'room-a', slug: 'room-a', nameTr: 'A'),
      VoiceRoomEntity(id: 'room-b', slug: 'room-b', nameTr: 'B', isPkLive: true),
    ];
    final next = patchVoiceRoomsInList(
      rooms,
      'room-a',
      (r) => r.copyWith(isPkLive: true),
    );
    expect(next[0].isPkLive, isTrue);
    expect(next[1].isPkLive, isTrue);
  });

  test('patchVoiceRoomsInList clears isPkLive on pk end', () {
    const rooms = [
      VoiceRoomEntity(id: 'room-a', slug: 'room-a', nameTr: 'A', isPkLive: true),
    ];
    final next = patchVoiceRoomsInList(
      rooms,
      'room-a',
      (r) => r.copyWith(isPkLive: false),
    );
    expect(next.single.isPkLive, isFalse);
  });

  test('patchVoiceRoomsInList updates isMusicPlaying', () {
    const rooms = [
      VoiceRoomEntity(id: 'room-a', slug: 'room-a', nameTr: 'A'),
    ];
    final next = patchVoiceRoomsInList(
      rooms,
      'room-a',
      (r) => r.copyWith(isMusicPlaying: true),
    );
    expect(next.single.isMusicPlaying, isTrue);
    expect(next.single.hasMusicActivity, isTrue);
  });
}
