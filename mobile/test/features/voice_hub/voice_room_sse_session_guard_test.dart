import 'package:canlifal_social/features/voice_hub/domain/voice_room_sse_session_guard.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('rejects events when session inactive', () {
    expect(
      voiceRoomAcceptsAttachedSseEvent(
        sessionActive: false,
        attachedRoomKey: 'room-a',
        eventRoomKey: 'room-a',
      ),
      isFalse,
    );
  });

  test('rejects attached key mismatch', () {
    expect(
      voiceRoomAcceptsAttachedSseEvent(
        sessionActive: true,
        attachedRoomKey: 'room-b',
        eventRoomKey: 'room-a',
        presenceApiKey: 'room-b',
      ),
      isFalse,
    );
  });

  test('accepts matching canonical room', () {
    expect(
      voiceRoomAcceptsAttachedSseEvent(
        sessionActive: true,
        attachedRoomKey: 'cuid-room-a',
        eventRoomKey: 'cuid-room-a',
        presenceApiKey: 'cuid-room-a',
      ),
      isTrue,
    );
  });

  test('rejects stale room event for new active room (Room A → Room B)', () {
    expect(
      voiceRoomAcceptsAttachedSseEvent(
        sessionActive: true,
        attachedRoomKey: 'room-b',
        eventRoomKey: 'room-a',
        activeLiveKey: 'room-b',
        presenceApiKey: 'room-b',
      ),
      isFalse,
    );
  });
}
