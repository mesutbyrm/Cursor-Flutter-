import 'package:canlifal_social/features/live_psychics/domain/psychic_trtc_identity.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('canonicalPsychicRoomChannel (PsychicTrtcIdentity)', () {
    const sessionId = 'sess-abc';

    test('empty raw core is empty; session alias still matches', () {
      expect(PsychicTrtcIdentity.core(null), '');
      expect(
        PsychicTrtcIdentity.sameChannel(null, sessionId, sessionId: sessionId),
        isTrue,
      );
    });

    test('room_ prefix normalizes to same channel', () {
      expect(
        PsychicTrtcIdentity.sameChannel(
          'room_$sessionId',
          sessionId,
          sessionId: sessionId,
        ),
        isTrue,
      );
    });

    test('distinct backend room id stays distinct', () {
      expect(
        PsychicTrtcIdentity.core('room_xyz'),
        'xyz',
      );
      expect(
        PsychicTrtcIdentity.sameChannel(
          'room_xyz',
          sessionId,
          sessionId: sessionId,
        ),
        isFalse,
      );
    });
  });
}
