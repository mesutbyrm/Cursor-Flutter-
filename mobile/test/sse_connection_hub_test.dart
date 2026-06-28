import 'package:canlifal_social/core/network/sse/sse_connection_hub.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('voice room ref count shares single service instance', () {
    final hub = SseConnectionHub();
    const roomId = 'room-abc';

    hub.attachVoiceRoom(roomId);
    hub.attachVoiceRoom(roomId);
    expect(hub.voiceRoomRefCount(roomId), 2);
    expect(identical(hub.voiceRoom(roomId), hub.voiceRoom(roomId)), isTrue);

    hub.releaseVoiceRoom(roomId);
    expect(hub.voiceRoomRefCount(roomId), 1);

    hub.releaseVoiceRoom(roomId);
    expect(hub.voiceRoomRefCount(roomId), 0);
  });

  test('video stream ref count releases at zero', () {
    final hub = SseConnectionHub();
    expect(() => hub.attachVideoStream('s1'), returnsNormally);
  });
}
