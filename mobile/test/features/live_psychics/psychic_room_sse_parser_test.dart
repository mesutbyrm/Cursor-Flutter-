import 'package:canlifal_social/features/live_psychics/data/services/psychic_room_sse_parser.dart';
import 'package:canlifal_social/features/live_psychics/domain/entities/psychic_session_status.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('parseSessionRoomSsePayload', () {
    test('timer_started updates room from timerStartedAt', () {
      final event = parseSessionRoomSsePayload(
        {
          'timerStartedAt': '2026-07-23T11:10:00.000Z',
          'maxMinutes': 15,
          'status': 'active',
        },
        sessionId: 'sess_timer',
      );

      expect(event, isA<PsychicRoomSseRoomUpdate>());
      final room = (event as PsychicRoomSseRoomUpdate).room;
      expect(room.sessionId, 'sess_timer');
      expect(room.maxMinutes, 15);
      expect(room.timerStartedAt, isNotNull);
    });

    test('time_extended uses nested room payload', () {
      final event = parseSessionRoomSsePayload(
        {
          'type': 'time_extended',
          'addedMinutes': 5,
          'newMaxMinutes': 20,
          'room': {
            'sessionId': 'sess_ext',
            'maxMinutes': 20,
            'remainingSeconds': 900,
            'status': 'active',
          },
        },
        sessionId: 'sess_ext',
      );

      expect(event, isA<PsychicRoomSseRoomUpdate>());
      final room = (event as PsychicRoomSseRoomUpdate).room;
      expect(room.maxMinutes, 20);
      expect(room.remainingSeconds, greaterThan(0));
    });

    test('session_ended from actualMinutesUsed', () {
      final event = parseSessionRoomSsePayload(
        {
          'actualMinutesUsed': 12,
          'endedBy': 'teller',
        },
        sessionId: 'sess_end',
      );

      expect(event, isA<PsychicRoomSseSessionEnded>());
      expect(
        (event as PsychicRoomSseSessionEnded).status,
        PsychicSessionStatus.ended,
      );
    });

    test('cancelled session maps to cancelled status', () {
      final event = parseSessionRoomSsePayload(
        {'type': 'session_cancelled', 'sessionId': 'sess_cancel'},
        sessionId: 'sess_cancel',
      );

      expect(event, isA<PsychicRoomSseSessionEnded>());
      expect(
        (event as PsychicRoomSseSessionEnded).status,
        PsychicSessionStatus.cancelled,
      );
    });

    test('chat message event', () {
      final event = parseSessionRoomSsePayload(
        {
          'id': 'msg_1',
          'senderId': 'user_a',
          'message': 'Merhaba',
          'createdAt': '2026-07-23T11:11:00.000Z',
        },
        sessionId: 'sess_chat',
        myUserId: 'user_b',
      );

      expect(event, isA<PsychicRoomSseMessage>());
      final msg = (event as PsychicRoomSseMessage).message;
      expect(msg.text, 'Merhaba');
      expect(msg.isMine, isFalse);
    });

    test('tip event parses amount', () {
      final event = parseSessionRoomSsePayload(
        {
          'type': 'tip_received',
          'amount': 50,
          'senderName': 'Ayşe',
        },
        sessionId: 'sess_tip',
      );

      expect(event, isA<PsychicRoomSseTip>());
      final tip = event as PsychicRoomSseTip;
      expect(tip.amount, 50);
      expect(tip.fromName, 'Ayşe');
    });
  });
}
