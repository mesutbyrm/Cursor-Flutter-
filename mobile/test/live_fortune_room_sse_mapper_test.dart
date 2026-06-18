import 'package:flutter_test/flutter_test.dart';

import 'package:canlifal_social/features/home/data/services/live_fortune_room_sse_mapper.dart';
import 'package:canlifal_social/features/home/domain/entities/live_fortune_room_sse_event.dart';

void main() {
  group('LiveFortuneRoomSseMapper', () {
    test('parseMessage reads room chat payload', () {
      final msg = LiveFortuneRoomSseMapper.parseMessage(
        {
          'id': 'm1',
          'senderId': 'u1',
          'senderName': 'Ayşe',
          'message': 'Merhaba',
          'createdAt': '2026-06-18T10:00:00.000Z',
        },
        myUserId: 'u2',
      );
      expect(msg, isNotNull);
      expect(msg!.text, 'Merhaba');
      expect(msg.isMine, isFalse);
    });

    test('parseRoomInfo reads timer fields', () {
      final room = LiveFortuneRoomSseMapper.parseRoomInfo(
        {
          'type': 'timer_started',
          'sessionId': 'sess_1',
          'timerStarted': true,
          'timerStartedAt': '2026-06-18T10:00:00.000Z',
          'maxMinutes': 10,
        },
        fallbackSessionId: 'sess_1',
      );
      expect(room, isNotNull);
      expect(room!.timerStarted, isTrue);
      expect(room.maxMinutes, 10);
    });

    test('parseSessionStatus detects accepted', () {
      final status = LiveFortuneRoomSseMapper.parseSessionStatus(
        {
          'type': 'session_update',
          'session': {
            'id': 'sess_1',
            'status': 'active',
            'tellerResponse': 'accepted',
            'roomId': 'room_sess_1',
          },
        },
        fallbackSessionId: 'sess_1',
      );
      expect(status, isNotNull);
      expect(status!.isActive, isTrue);
      expect(status.trtcRoomId, 'room_sess_1');
    });
  });

  group('liveFortuneRoomSseKindFrom', () {
    test('maps production event names', () {
      expect(liveFortuneRoomSseKindFrom('message'), LiveFortuneRoomSseKind.message);
      expect(liveFortuneRoomSseKindFrom('timer_started'), LiveFortuneRoomSseKind.timerStarted);
      expect(liveFortuneRoomSseKindFrom('session_update'), LiveFortuneRoomSseKind.sessionUpdate);
      expect(liveFortuneRoomSseKindFrom('ended'), LiveFortuneRoomSseKind.sessionEnded);
    });
  });
}
