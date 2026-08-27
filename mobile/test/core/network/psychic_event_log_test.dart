import 'package:canlifal_social/core/network/psychic_event_log.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('PsychicEventLog sanitizes secret fields', () {
    final sanitized = PsychicEventLog.sanitize({
      'sessionId': 'sess-1',
      'userSig': 'eyJhbGciOiJIUzI1NiJ9.payload.signature',
      'token': 'secret',
      'roomId': 'room_abc',
    });
    expect(sanitized['sessionId'], 'sess-1');
    expect(sanitized['roomId'], 'room_abc');
    expect(sanitized.containsKey('userSig'), isFalse);
    expect(
      PsychicEventLog.sanitize({
        'sessionId': 's1',
        'trtcRoomId': 'fortune_room_s1',
        'userId': 'u1',
        'connectionState': 'connected',
        'userSig': 'should-not-leak',
      }).containsKey('userSig'),
      isFalse,
    );
  });
}
