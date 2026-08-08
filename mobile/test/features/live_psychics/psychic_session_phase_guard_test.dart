import 'package:canlifal_social/features/live_psychics/domain/psychic_session_phase.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('PsychicSessionPhaseGuard allows valid transitions', () {
    expect(
      PsychicSessionPhaseGuard.canTransition(
        PsychicSessionPhase.idle,
        PsychicSessionPhase.requesting,
      ),
      isTrue,
    );
    expect(
      PsychicSessionPhaseGuard.canTransition(
        PsychicSessionPhase.joining,
        PsychicSessionPhase.connected,
      ),
      isTrue,
    );
    expect(
      PsychicSessionPhaseGuard.canTransition(
        PsychicSessionPhase.connected,
        PsychicSessionPhase.ending,
      ),
      isTrue,
    );
  });

  test('PsychicSessionPhaseGuard blocks invalid transitions', () {
    expect(
      PsychicSessionPhaseGuard.canTransition(
        PsychicSessionPhase.ended,
        PsychicSessionPhase.connected,
      ),
      isFalse,
    );
    expect(
      PsychicSessionPhaseGuard.canTransition(
        PsychicSessionPhase.requesting,
        PsychicSessionPhase.connected,
      ),
      isFalse,
    );
    expect(
      PsychicSessionPhaseGuard.transition(
        PsychicSessionPhase.ending,
        PsychicSessionPhase.requesting,
      ),
      isNull,
    );
  });
}
