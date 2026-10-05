import 'package:canlifal_social/features/trtc/domain/entities/live_join_room_result.dart';
import 'package:canlifal_social/features/voice_hub/domain/voice_room_live_join_mapper.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('participantsToPresence maps join-room participants', () {
    const participants = [
      LiveJoinParticipant(
        userId: 'u1',
        userName: 'Ayşe',
        seatIndex: 2,
      ),
    ];
    final list = VoiceRoomLiveJoinMapper.participantsToPresence(participants);
    expect(list, hasLength(1));
    expect(list.first.id, 'u1');
    expect(list.first.seatIndex, 2);
  });

  test('seatsToSlots maps join-room seats', () {
    const seats = [
      LiveJoinSeat(seatIndex: 0, userId: 'u1', isMicOn: true),
    ];
    final slots = VoiceRoomLiveJoinMapper.seatsToSlots(seats);
    expect(slots.first.index, 0);
    expect(slots.first.userId, 'u1');
    expect(slots.first.micOn, isTrue);
  });
}
