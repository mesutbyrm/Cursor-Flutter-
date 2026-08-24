import 'package:flutter_test/flutter_test.dart';

import 'package:canlifal_social/core/performance/voice_room_entry_perf.dart';
import 'package:canlifal_social/features/trtc/domain/entities/trtc_credentials.dart';

void main() {
  test('takeTrtc returns cached credentials once', () {
    const cred = TrtcCredentials(
      sdkAppId: 1,
      userId: 'u1',
      userSig: 'sig',
      roomId: 'voice_room_room-a',
    );
    VoiceRoomEntryPerf.testPutTrtc(
      userId: 'u1',
      roomId: 'voice_room_room-a',
      cred: cred,
    );

    expect(
      VoiceRoomEntryPerf.takeTrtc(
        userId: 'u1',
        roomId: 'voice_room_room-a',
      ),
      cred,
    );
    expect(
      VoiceRoomEntryPerf.takeTrtc(
        userId: 'u1',
        roomId: 'voice_room_room-a',
      ),
      isNull,
    );
  });
}
