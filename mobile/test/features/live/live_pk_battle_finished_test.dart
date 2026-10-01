import 'package:canlifal_social/features/live/domain/pk/live_pk_broadcast_stage.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('tie status does not finish PK before endsAt', () {
    final endsAt =
        DateTime.now().toUtc().add(const Duration(minutes: 3)).toIso8601String();
    expect(
      livePkBattleFinished(
        status: 'tie',
        battle: {'endsAt': endsAt, 'status': 'tie'},
      ),
      isFalse,
    );
  });

  test('tie status finishes after endsAt', () {
    final endsAt = DateTime.now()
        .toUtc()
        .subtract(const Duration(minutes: 1))
        .toIso8601String();
    expect(
      livePkBattleFinished(
        status: 'tie',
        battle: {'endsAt': endsAt, 'status': 'tie'},
      ),
      isTrue,
    );
  });

  test('completed status always finished', () {
    expect(livePkBattleFinished(status: 'completed', battle: const {}), isTrue);
  });
}
