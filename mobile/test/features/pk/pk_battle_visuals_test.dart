import 'package:canlifal_social/features/pk/presentation/widgets/pk_battle_visuals.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('pkSideOutcome ahead/behind/tied', () {
    expect(
      pkSideOutcome(
        isLeft: true,
        leftScore: 10,
        rightScore: 5,
        battleActive: true,
      ),
      PkSideOutcome.ahead,
    );
    expect(
      pkSideOutcome(
        isLeft: false,
        leftScore: 10,
        rightScore: 5,
        battleActive: true,
      ),
      PkSideOutcome.behind,
    );
    expect(
      pkSideOutcome(
        isLeft: true,
        leftScore: 3,
        rightScore: 3,
        battleActive: true,
      ),
      PkSideOutcome.tied,
    );
  });

  test('pkBattleSecondsLeftFromMap reads secondsLeft', () {
    expect(
      pkBattleSecondsLeftFromMap({'secondsLeft': 42}),
      42,
    );
  });
}
