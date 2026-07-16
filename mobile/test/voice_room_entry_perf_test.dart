import 'package:flutter_test/flutter_test.dart';

import 'package:canlifal_social/core/performance/voice_room_entry_perf.dart';
import 'package:canlifal_social/features/agora/domain/entities/agora_credentials.dart';
import 'package:canlifal_social/features/trtc/domain/entities/trtc_credentials.dart';

void main() {
  test('takeTrtc returns cached credentials once', () {
    const cred = TrtcCredentials(
      sdkAppId: 1,
      userId: 'u1',
      userSig: 'sig',
      roomId: 'room-a',
    );
    VoiceRoomEntryPerf.testPutTrtc(
      userId: 'u1',
      roomId: 'room-a',
      cred: cred,
    );

    expect(
      VoiceRoomEntryPerf.takeTrtc(userId: 'u1', roomId: 'room-a'),
      cred,
    );
    expect(
      VoiceRoomEntryPerf.takeTrtc(userId: 'u1', roomId: 'room-a'),
      isNull,
    );
  });

  test('takeAgora returns cached credentials once', () {
    VoiceRoomEntryPerf.testPutAgora(
      userId: 'u1',
      roomId: 'room-1',
      role: 'audience',
      cred: const AgoraCredentials(
        appId: 'app',
        token: 'tok',
        channelName: 'voice_room_room-1',
        uid: 42,
      ),
    );
    final taken = VoiceRoomEntryPerf.takeAgora(
      userId: 'u1',
      roomId: 'room-1',
      role: 'audience',
    );
    expect(taken?.token, 'tok');
    expect(
      VoiceRoomEntryPerf.takeAgora(
        userId: 'u1',
        roomId: 'room-1',
        role: 'audience',
      ),
      isNull,
    );
  });
}
