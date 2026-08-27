import 'package:flutter_test/flutter_test.dart';

import 'package:canlifal_social/features/live_psychics/domain/psychic_trtc_connection.dart';
import 'package:canlifal_social/features/live_psychics/domain/psychic_trtc_identity.dart';

void main() {
  group('PsychicTrtcIdentity roomId consistency', () {
    const sessionId = 'sess-abc';

    test('fortune_room / room_ / sessionId are the same channel', () {
      expect(
        PsychicTrtcIdentity.sameChannel(
          'fortune_room_$sessionId',
          sessionId,
          sessionId: sessionId,
        ),
        isTrue,
      );
      expect(
        PsychicTrtcIdentity.sameChannel(
          'room_$sessionId',
          sessionId,
          sessionId: sessionId,
        ),
        isTrue,
      );
      expect(
        PsychicTrtcIdentity.sameChannel(
          'fortune_room_$sessionId',
          'room_$sessionId',
          sessionId: sessionId,
        ),
        isTrue,
      );
    });

    test('distinct cores are not the same channel', () {
      expect(
        PsychicTrtcIdentity.sameChannel(
          'fortune_room_aaa',
          'room_bbb',
          sessionId: sessionId,
        ),
        isFalse,
      );
    });

    test('SSE/business roomId alias is drift, not a new TRTC room', () {
      expect(
        PsychicTrtcIdentity.isAliasDrift(
          sessionId: sessionId,
          joinedTrtcRoom: 'fortune_room_$sessionId',
          incomingRoomId: 'room_$sessionId',
        ),
        isTrue,
      );
      expect(
        PsychicTrtcIdentity.isAliasDrift(
          sessionId: sessionId,
          joinedTrtcRoom: sessionId,
          incomingRoomId: 'fortune_room_$sessionId',
        ),
        isTrue,
      );
    });
  });

  group('PsychicTrtcConnection single-flight + lifecycle', () {
    test('single join in-flight — second join rejected', () {
      final conn = PsychicTrtcConnection();
      expect(conn.tryBeginJoin(), isTrue);
      expect(conn.tryBeginJoin(), isFalse);
      expect(conn.joinInFlight, isTrue);
    });

    test('reconnect only on real connection loss, not while in room on resume', () {
      final conn = PsychicTrtcConnection()..phase = PsychicTrtcPhase.connected;
      expect(
        conn.shouldReconnect(
          reason: PsychicTrtcReconnectReason.connectionLost,
          inRoom: true,
        ),
        isTrue,
      );
      expect(
        conn.shouldReconnect(
          reason: PsychicTrtcReconnectReason.appResumedNotInRoom,
          inRoom: true,
        ),
        isFalse,
      );
      expect(
        conn.shouldReconnect(
          reason: PsychicTrtcReconnectReason.networkRecovered,
          inRoom: true,
        ),
        isFalse,
      );
    });

    test('reconnect is single-flight', () {
      final conn = PsychicTrtcConnection()..phase = PsychicTrtcPhase.connected;
      expect(
        conn.tryBeginReconnect(
          PsychicTrtcReconnectReason.connectionLost,
          inRoom: false,
        ),
        isTrue,
      );
      expect(
        conn.tryBeginReconnect(
          PsychicTrtcReconnectReason.connectionLost,
          inRoom: false,
        ),
        isFalse,
      );
    });

    test('remote audio/video is not a reconnect reason', () {
      expect(
        PsychicTrtcReconnectReason.values.map((e) => e.name),
        ['connectionLost', 'networkRecovered', 'appResumedNotInRoom'],
      );
    });

    test('T0-T60 business roomId polls do not reconnect while in room', () {
      final conn = PsychicTrtcConnection();
      conn.tryBeginJoin();
      conn.markConnected(
        sessionId: 's1',
        tokenRequestRoomId: 's1',
        joinedTrtcRoomId: 'fortune_room_s1',
        joinedUserId: 'u1',
      );
      for (final incoming in ['s1', 'room_s1', 'fortune_room_s1']) {
        expect(
          PsychicTrtcIdentity.isAliasDrift(
            sessionId: 's1',
            joinedTrtcRoom: 'fortune_room_s1',
            incomingRoomId: incoming,
          ),
          isTrue,
        );
        expect(
          conn.shouldReconnect(
            reason: PsychicTrtcReconnectReason.networkRecovered,
            inRoom: true,
          ),
          isFalse,
        );
      }
    });

    test('session dispose clears locked TRTC ids', () {
      final conn = PsychicTrtcConnection();
      expect(conn.tryBeginJoin(), isTrue);
      conn.markConnected(
        sessionId: 's1',
        tokenRequestRoomId: 's1',
        joinedTrtcRoomId: 'fortune_room_s1',
        joinedUserId: 'u1',
      );
      expect(conn.tryBeginLeave(), isTrue);
      conn.markLeft();
      expect(conn.joinedTrtcRoomId, isNull);
      expect(conn.tokenRequestRoomId, isNull);
      expect(conn.joinedUserId, isNull);
      expect(conn.phase, PsychicTrtcPhase.left);
    });

    test('session switch: Psychic B does not reuse Psychic A lock', () {
      final a = PsychicTrtcConnection();
      a.tryBeginJoin();
      a.markConnected(
        sessionId: 'psychic-a',
        tokenRequestRoomId: 'psychic-a',
        joinedTrtcRoomId: 'fortune_room_a',
        joinedUserId: 'u1',
      );
      expect(a.isForeignSession('psychic-b'), isTrue);

      final b = PsychicTrtcConnection()..sessionId = 'psychic-b';
      expect(b.joinedTrtcRoomId, isNull);
      expect(b.tokenRequestRoomId, isNull);
      expect(
        b.alreadyJoined(
          sessionId: 'psychic-b',
          trtcRoomId: 'fortune_room_a',
          inRoom: true,
        ),
        isFalse,
      );
    });

    test('foreground/background: resume reconnects only when not in room', () {
      final conn = PsychicTrtcConnection()..phase = PsychicTrtcPhase.connected;
      expect(
        conn.shouldReconnect(
          reason: PsychicTrtcReconnectReason.appResumedNotInRoom,
          inRoom: false,
        ),
        isTrue,
      );
      conn.phase = PsychicTrtcPhase.leaving;
      expect(
        conn.shouldReconnect(
          reason: PsychicTrtcReconnectReason.appResumedNotInRoom,
          inRoom: false,
        ),
        isFalse,
      );
    });

    test('leaving/disposed never reconnect', () {
      final conn = PsychicTrtcConnection()..phase = PsychicTrtcPhase.disposed;
      expect(
        conn.shouldReconnect(
          reason: PsychicTrtcReconnectReason.connectionLost,
          inRoom: false,
        ),
        isFalse,
      );
    });

    test('already joined same engine/room skips second enter', () {
      final conn = PsychicTrtcConnection();
      conn.tryBeginJoin();
      conn.markConnected(
        sessionId: 's1',
        tokenRequestRoomId: 's1',
        joinedTrtcRoomId: 'fortune_room_s1',
        joinedUserId: 'u1',
      );
      expect(
        conn.alreadyJoined(
          sessionId: 's1',
          trtcRoomId: 'room_s1',
          inRoom: true,
        ),
        isTrue,
      );
    });
  });

  group('PsychicTrtcListenerBind duplicate prevention', () {
    test('attach once, second attach is no-op', () {
      final bind = PsychicTrtcListenerBind();
      expect(bind.tryAttach(), isTrue);
      expect(bind.tryAttach(), isFalse);
      expect(bind.attached, isTrue);
      expect(bind.tryDetach(), isTrue);
      expect(bind.tryDetach(), isFalse);
      expect(bind.tryAttach(), isTrue);
    });
  });

  group('token / session consistency', () {
    test('telemetry never includes token fields', () {
      final conn = PsychicTrtcConnection();
      conn.markConnected(
        sessionId: 's1',
        tokenRequestRoomId: 's1',
        joinedTrtcRoomId: 'fortune_room_s1',
        joinedUserId: 'u1',
      );
      final fields = conn.telemetry(inRoom: true, online: true);
      expect(fields.containsKey('userSig'), isFalse);
      expect(fields.containsKey('token'), isFalse);
      expect(fields['sessionId'], 's1');
      expect(fields['trtcRoomId'], 'fortune_room_s1');
      expect(fields['userId'], 'u1');
      expect(fields['connectionState'], 'connected');
    });
  });
}
