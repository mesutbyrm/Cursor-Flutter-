import 'package:canlifal_social/features/live_psychics/presentation/controllers/psychic_invite_poll_gate.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('first poll seeds pending without presenting', () {
    final gate = PsychicInvitePollGate();
    expect(
      gate.takeNewPendingSessionIds(['s1', 's2']),
      isEmpty,
    );
    expect(
      gate.takeNewPendingSessionIds(['s1', 's2']),
      isEmpty,
    );
  });

  test('subsequent poll returns only new session ids', () {
    final gate = PsychicInvitePollGate();
    gate.takeNewPendingSessionIds(['s1']);
    expect(gate.takeNewPendingSessionIds(['s1', 's2']), ['s2']);
    expect(gate.takeNewPendingSessionIds(['s1', 's2', 's3']), ['s3']);
  });
}
