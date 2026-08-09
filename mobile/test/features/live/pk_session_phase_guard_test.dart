import 'package:canlifal_social/core/network/pk_event_log.dart';
import 'package:canlifal_social/features/live/domain/pk/pk_session_phase.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('PkSessionPhaseGuard blocks duplicate same-phase transition', () {
    expect(
      PkSessionPhaseGuard.canTransition(
        PkSessionPhase.requesting,
        PkSessionPhase.requesting,
      ),
      isFalse,
    );
  });

  test('PkSessionPhaseGuard allows request to incoming', () {
    expect(
      PkSessionPhaseGuard.canTransition(
        PkSessionPhase.requesting,
        PkSessionPhase.incoming,
      ),
      isTrue,
    );
  });

  test('PkEventLog sanitizes secrets', () {
    final out = PkEventLog.sanitize({
      'matchId': 'm1',
      'token': 'secret',
    });
    expect(out['matchId'], 'm1');
    expect(out.containsKey('token'), isFalse);
  });
}
