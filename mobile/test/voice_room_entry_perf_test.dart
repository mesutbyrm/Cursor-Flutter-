import 'package:flutter_test/flutter_test.dart';

import 'package:canlifal_social/core/performance/voice_room_entry_perf.dart';
import 'package:canlifal_social/features/agora/domain/entities/agora_credentials.dart';

void main() {
  test('VoiceRoomEntryPerf.takeAgora returns cached credentials', () {
    VoiceRoomEntryPerf.testPutAgora(
      userId: 'u1',
      roomId: 'room-1',
      role: 'audience',
      cred: AgoraCredentials(
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
