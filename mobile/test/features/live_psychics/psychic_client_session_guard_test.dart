import 'package:canlifal_social/features/live_psychics/domain/entities/psychic_session_status.dart';
import 'package:canlifal_social/features/live_psychics/domain/psychic_client_session_guard.dart';
import 'package:canlifal_social/features/live_psychics/domain/repositories/live_psychics_repository.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('blocks waiting and active client sessions', () {
    expect(
      PsychicClientSessionGuard.blocksNewBooking(PsychicSessionStatus.pending),
      isTrue,
    );
    expect(
      PsychicClientSessionGuard.blocksNewBooking(PsychicSessionStatus.active),
      isTrue,
    );
    expect(
      PsychicClientSessionGuard.blocksNewBooking(PsychicSessionStatus.ended),
      isFalse,
    );
  });

  test('firstBlockingFromActive skips teller and terminal sessions', () {
    const active = [
      PsychicSessionStatusResult(
        sessionId: 'teller_sess',
        status: PsychicSessionStatus.active,
        isClient: false,
      ),
      PsychicSessionStatusResult(
        sessionId: 'ended_sess',
        status: PsychicSessionStatus.ended,
        isClient: true,
      ),
      PsychicSessionStatusResult(
        sessionId: 'client_wait',
        status: PsychicSessionStatus.pending,
        isClient: true,
        tellerProfileId: 'teller_a',
      ),
    ];

    final blocked = PsychicClientSessionGuard.firstBlockingFromActive(active);
    expect(blocked?.sessionId, 'client_wait');
    expect(blocked?.tellerProfileId, 'teller_a');
  });
}
