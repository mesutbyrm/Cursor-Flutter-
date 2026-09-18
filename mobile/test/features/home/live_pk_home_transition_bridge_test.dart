import 'package:canlifal_social/features/live/presentation/navigation/live_pk_home_transition_bridge.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('LivePkHomeTransitionNotifier tracks phase without PK RTC', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final n = container.read(livePkHomeTransitionProvider.notifier);
    expect(container.read(livePkHomeTransitionProvider).phase,
        LivePkHomeTransitionPhase.idle);

    n.noteEnteringLive(streamId: 's1');
    expect(container.read(livePkHomeTransitionProvider).phase,
        LivePkHomeTransitionPhase.enteringLive);
    expect(container.read(livePkHomeTransitionProvider).streamId, 's1');

    n.noteEnteringPkShell(battleId: 'b1');
    expect(container.read(livePkHomeTransitionProvider).phase,
        LivePkHomeTransitionPhase.enteringPkShell);

    n.reset();
    expect(container.read(livePkHomeTransitionProvider).phase,
        LivePkHomeTransitionPhase.idle);
  });
}
