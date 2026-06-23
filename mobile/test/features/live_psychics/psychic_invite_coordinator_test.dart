import 'package:flutter_test/flutter_test.dart';
import 'package:canlifal_social/features/live_psychics/presentation/controllers/psychic_invite_coordinator.dart';

void main() {
  group('PsychicInviteCoordinator', () {
    test('requestPresent dedupes same session within 60s', () {
      var calls = 0;
      PsychicInviteCoordinator.onRequestPresent = () => calls++;

      PsychicInviteCoordinator.requestPresent(sessionId: 'sess-1');
      PsychicInviteCoordinator.requestPresent(sessionId: 'sess-1');
      PsychicInviteCoordinator.requestPresent(sessionId: 'sess-2');

      expect(calls, 2);
      PsychicInviteCoordinator.onRequestPresent = null;
    });

    test('shouldDebounceShown blocks repeat for 60s', () {
      PsychicInviteCoordinator.markDialogShown('sess-a');
      expect(PsychicInviteCoordinator.shouldDebounceShown('sess-a'), isTrue);
      expect(PsychicInviteCoordinator.shouldDebounceShown('sess-b'), isFalse);
    });
  });
}
