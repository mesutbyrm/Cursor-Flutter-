import 'package:flutter_test/flutter_test.dart';
import 'package:canlifal_social/features/voice_hub/domain/entities/speak_request_status.dart';

void main() {
  group('SpeakRequestStatus.fromJson', () {
    test('parses pending request', () {
      final status = SpeakRequestStatus.fromJson({
        'request': {
          'id': 'req-1',
          'status': 'pending',
        },
        'blocked': false,
      });
      expect(status.pending, isTrue);
      expect(status.requestId, 'req-1');
      expect(status.blocked, isFalse);
    });

    test('parses blocked user', () {
      final status = SpeakRequestStatus.fromJson({
        'request': null,
        'blocked': true,
        'blockReason': 'Kural ihlali',
      });
      expect(status.blocked, isTrue);
      expect(status.blockReason, 'Kural ihlali');
      expect(status.pending, isFalse);
    });
  });

  group('VoiceSpeakRequestIncoming.fromPayload', () {
    test('maps voice_request SSE payload', () {
      final item = VoiceSpeakRequestIncoming.fromPayload('room-1', {
        'userId': 'u1',
        'userName': 'Ayşe',
        'requestId': 'r1',
        'message': 'Merhaba',
      });
      expect(item.roomKey, 'room-1');
      expect(item.userId, 'u1');
      expect(item.userName, 'Ayşe');
      expect(item.requestId, 'r1');
      expect(item.message, 'Merhaba');
      expect(item.dedupeKey, 'room-1:r1');
    });
  });
}
