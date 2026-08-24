import 'package:canlifal_social/features/live_psychics/domain/session_room_sse_event.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('inferSessionRoomSseEventType', () {
    test('detects session_ended from actualMinutesUsed', () {
      expect(
        inferSessionRoomSseEventType({
          'actualMinutesUsed': 12,
          'endedBy': 'teller',
        }),
        'session_ended',
      );
    });

    test('detects time_extended from addedMinutes', () {
      expect(
        inferSessionRoomSseEventType({
          'addedMinutes': 5,
          'newMaxMinutes': 20,
          'by': 'teller',
        }),
        'time_extended',
      );
    });

    test('detects timer_started from timerStartedAt', () {
      expect(
        inferSessionRoomSseEventType({
          'timerStartedAt': '2026-07-23T11:10:00.000Z',
        }),
        'timer_started',
      );
    });

    test('detects message from senderId and message', () {
      expect(
        inferSessionRoomSseEventType({
          'id': 'rm_2201',
          'senderId': 'u_7781',
          'message': 'Merhaba',
          'createdAt': '2026-07-23T11:11:00.000Z',
        }),
        'message',
      );
    });

    test('detects connected handshake payload', () {
      expect(
        inferSessionRoomSseEventType({
          'sessionId': 'sess_4410',
          'isUser': true,
          'status': 'active',
        }),
        'connected',
      );
    });

    test('prefers explicit type when present', () {
      expect(
        inferSessionRoomSseEventType({
          'type': 'gift',
          'message': 'ignored',
        }),
        'gift',
      );
    });
  });

  group('isSessionRoomSseCommentBlock', () {
    test('treats heartbeat comment as non-data', () {
      expect(isSessionRoomSseCommentBlock(': heartbeat'), isTrue);
    });
  });
}
