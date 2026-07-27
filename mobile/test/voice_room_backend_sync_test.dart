import 'package:canlifal_social/features/voice_hub/domain/entities/voice_room_seat_slot.dart';
import 'package:canlifal_social/features/voice_hub/domain/entities/voice_room_state_snapshot.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('parseVoiceRoomSeatMap pads to 11 seats', () {
    final seats = parseVoiceRoomSeatMap([
      {'index': 0, 'userId': 'u1', 'name': 'Ali', 'micOn': true},
      null,
    ]);
    expect(seats.length, 11);
    expect(seats[0].userId, 'u1');
    expect(seats[0].micOn, true);
    expect(seats[1].isEmpty, true);
  });

  test('VoiceRoomStateSnapshot parses participants and trtc', () {
    final snap = VoiceRoomStateSnapshot.fromJson(
      {
        'ownerId': 'owner-1',
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
  });
}
