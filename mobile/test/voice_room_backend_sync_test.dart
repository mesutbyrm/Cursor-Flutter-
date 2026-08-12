import 'package:canlifal_social/features/voice_hub/domain/entities/voice_room_seat_slot.dart';
import 'package:canlifal_social/features/voice_hub/domain/entities/voice_room_state_snapshot.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('parseVoiceRoomSeatMap pads to target seat count', () {
    final seats = parseVoiceRoomSeatMap([
      {'index': 0, 'userId': 'u1', 'name': 'Ali', 'micOn': true},
      null,
    ], targetCount: 12);
    expect(seats.length, 12);
    expect(seats[0].userId, 'u1');
    expect(seats[0].micOn, true);
    expect(seats[1].isEmpty, true);
  });

  test('parseVoiceRoomSeatMap respects 8-seat rooms', () {
    final seats = parseVoiceRoomSeatMap([], targetCount: 8);
    expect(seats.length, 8);
    expect(seats.every((s) => s.isEmpty), isTrue);
  });

  test('VoiceRoomStateSnapshot parses participants, trtc and seatCount', () {
    final snap = VoiceRoomStateSnapshot.fromJson(
      {
        'ownerId': 'owner-1',
        'room': {'seatCount': 10, 'maxUsers': 15},
        'participants': [
          {
            'id': 'u1',
            'name': 'Ali',
            'seatIndex': 2,
            'micOn': true,
          },
        ],
        'trtc': {
          'sdkAppId': 1400,
          'userId': 'u1',
          'userSig': 'sig',
          'trtcRoomId': 'voice_room_abc',
          'numericUid': 42,
        },
      },
      roomId: 'abc',
    );
    expect(snap.ownerId, 'owner-1');
    expect(snap.participants.length, 1);
    expect(snap.participants.first.seatIndex, 2);
    expect(snap.participants.first.micOn, true);
    expect(snap.trtc?.effectiveStrRoomId, 'voice_room_abc');
    expect(snap.trtc?.numericUid, 42);
    expect(snap.seatCount, 10);
    expect(snap.maxUsers, 15);
    expect(snap.seats.length, 10);
  });
}
