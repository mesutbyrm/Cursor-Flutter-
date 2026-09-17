import 'package:canlifal_social/features/live/presentation/providers/live_pk_ended_lock_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('ended celebration acquires once per battle id', () {
    final container = ProviderContainer();
    final n = container.read(livePkEndedLockProvider.notifier);
    expect(n.tryAcquireEndedCelebration('b1'), isTrue);
    expect(n.tryAcquireEndedCelebration('b1'), isFalse);
    expect(n.tryAcquireEndedCelebration('b2'), isTrue);
    n.release('b1');
    expect(n.tryAcquireEndedCelebration('b1'), isTrue);
    container.dispose();
  });
}
