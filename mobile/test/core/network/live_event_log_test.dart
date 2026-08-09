import 'package:canlifal_social/core/network/live_event_log.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('LiveEventLog sanitizes secret fields', () {
    final sanitized = LiveEventLog.sanitize({
      'streamId': 'abc123',
      'userSig': 'eyJhbGciOiJIUzI1NiJ9.payload.signature',
      'token': 'secret-token',
      'role': 'host',
    });
    expect(sanitized['streamId'], 'abc123');
    expect(sanitized['role'], 'host');
    expect(sanitized.containsKey('userSig'), isFalse);
    expect(sanitized.containsKey('token'), isFalse);
  });
}
