import 'package:flutter_test/flutter_test.dart';

import 'package:canlifal_social/core/diagnostics/cf_auto_detect.dart';
import 'package:canlifal_social/core/diagnostics/cf_diag.dart';
import 'package:canlifal_social/features/live_psychics/domain/entities/psychic_room_entity.dart';
import 'package:canlifal_social/features/live_psychics/domain/entities/psychic_session_status.dart';

void main() {
  setUp(() {
    CfDiag.resetForTest();
    CfAutoDetect.resetForTest();
  });

  group('CfAutoDetect', () {
    test('TIMER_DRIFT fires only above 2 s and is rate-limited', () {
      expect(
        CfAutoDetect.timerDrift(
          sessionId: 's1',
          clientRemaining: 100,
          serverRemaining: 98,
        ),
        isFalse,
      );
      expect(
        CfAutoDetect.timerDrift(
          sessionId: 's1',
          clientRemaining: 100,
          serverRemaining: 90,
        ),
        isTrue,
      );
      CfAutoDetect.timerDrift(
        sessionId: 's1',
        clientRemaining: 100,
        serverRemaining: 80,
      );
      final hits =
          CfDiag.entries.where((e) => e.message == 'CRITICAL TIMER_DRIFT');
      expect(hits.length, 1);
      expect(hits.single.level, CfLevel.error);
    });

    test('AUDIO_ACTIVE_WITHOUT_SEAT', () {
      expect(
        CfAutoDetect.audioWithoutSeat(
          roomId: 'r1',
          publishing: true,
          localAudioOn: true,
        ),
        isFalse,
      );
      expect(
        CfAutoDetect.audioWithoutSeat(
          roomId: 'r1',
          publishing: false,
          localAudioOn: false,
        ),
        isFalse,
      );
      expect(
        CfAutoDetect.audioWithoutSeat(
          roomId: 'r1',
          publishing: false,
          localAudioOn: true,
        ),
        isTrue,
      );
    });

    test('TRTC_JOINED_TWICE records both room ids', () {
      CfAutoDetect.trtcJoinedTwice(activeRoomId: 'a', newRoomId: 'b');
      final e = CfDiag.entries.single;
      expect(e.category, CfCategory.trtc);
      expect(e.message, 'CRITICAL TRTC_JOINED_TWICE');
    });
  });

  group('Psychic timer does not freeze between syncs', () {
    test('remainingSeconds advances from the server snapshot', () {
      final t0 = DateTime(2026, 10, 7, 12);
      final room = PsychicRoomEntity(
        sessionId: 's1',
        status: PsychicSessionStatus.fromApi('active'),
        maxMinutes: 10,
        timerStarted: true,
        elapsedSeconds: 60,
        snapshotAt: t0,
      );
      expect(room.remainingSecondsAt(t0), 540);
      expect(room.remainingSecondsAt(t0.add(const Duration(seconds: 3))), 537);
      expect(room.remainingSecondsAt(t0.add(const Duration(hours: 1))), 0);
    });

    test('without snapshot behaves as before', () {
      final room = PsychicRoomEntity(
        sessionId: 's1',
        status: PsychicSessionStatus.fromApi('active'),
        maxMinutes: 10,
        timerStarted: true,
        elapsedSeconds: 60,
      );
      expect(room.remainingSecondsAt(DateTime(2030)), 540);
    });
  });
}
