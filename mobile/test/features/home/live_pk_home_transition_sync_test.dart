import 'package:canlifal_social/features/live/presentation/navigation/live_pk_home_transition_bridge.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('syncLivePkHomeTransitionFromBattle maps active PK to pkActive', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    syncLivePkHomeTransitionState(
      container.read(livePkHomeTransitionProvider.notifier),
      streamId: 'stream-1',
      battle: {
        'id': 'battle-9',
        'status': 'active',
      },
    );

    final s = container.read(livePkHomeTransitionProvider);
    expect(s.phase, LivePkHomeTransitionPhase.pkActive);
    expect(s.battleId, 'battle-9');
    expect(s.streamId, 'stream-1');
  });

  test('syncLivePkHomeTransitionFromBattle resets on ended', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    container
        .read(livePkHomeTransitionProvider.notifier)
        .notePkActive();
    syncLivePkHomeTransitionState(
      container.read(livePkHomeTransitionProvider.notifier),
      battle: {'id': 'b', 'status': 'ended'},
    );
    expect(container.read(livePkHomeTransitionProvider).phase,
        LivePkHomeTransitionPhase.idle);
  });
}
