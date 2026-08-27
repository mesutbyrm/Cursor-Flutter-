import 'package:flutter_test/flutter_test.dart';

import 'package:canlifal_social/core/network/sse/sse_connection_hub.dart';

void main() {
  test('hub pause/resume does not create extra voice room leases', () async {
    final hub = SseConnectionHub();
    hub.attachVoiceRoom('room-a');
    expect(hub.voiceRoomRefCount('room-a'), 1);
    expect(hub.activeVoiceRoomCount, 1);

    await hub.pauseAllForBackground();
    expect(hub.voiceRoomRefCount('room-a'), 1);
    expect(hub.activeVoiceRoomCount, 1);

    await hub.resumeAllFromBackground();
    expect(hub.voiceRoomRefCount('room-a'), 1);
    expect(hub.activeVoiceRoomCount, 1);

    hub.forceReleaseVoiceRoom('room-a');
    expect(hub.voiceRoomRefCount('room-a'), 0);
    expect(hub.activeVoiceRoomCount, 0);

    await hub.dispose();
  });

  test('forceRelease clears leftover room subscription', () async {
    final hub = SseConnectionHub();
    hub.attachVoiceRoom('room-a');
    hub.attachVoiceRoom('room-a');
    expect(hub.voiceRoomRefCount('room-a'), 2);
    hub.forceReleaseVoiceRoom('room-a');
    expect(hub.voiceRoomRefCount('room-a'), 0);
    await hub.dispose();
  });
}
