import 'package:flutter_test/flutter_test.dart';

import 'package:canlifal_social/features/live/domain/pk/live_pk_outcome_latch.dart';

void main() {
  test('latches ended label per battle id', () {
    final latch = LivePkOutcomeLatch();
    final first = latch.resolve(
      currentBattleId: 'b1',
      ended: true,
      computedLabel: 'Ali kazandı!',
    );
    expect(first, 'Ali kazandı!');
    final flicker = latch.resolve(
      currentBattleId: 'b1',
      ended: false,
      computedLabel: 'PK devam ediyor!',
    );
    expect(flicker, 'Ali kazandı!');
    final again = latch.resolve(
      currentBattleId: 'b1',
      ended: true,
      computedLabel: 'Berabere!',
    );
    expect(again, 'Ali kazandı!');
  });
}
