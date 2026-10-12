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

  test('completed status not finished before endsAt', () {
    final endsAt =
        DateTime.now().toUtc().add(const Duration(minutes: 2)).toIso8601String();
    expect(
      livePkBattleFinished(
        status: 'completed',
        battle: {'endsAt': endsAt, 'status': 'completed'},
      ),
      isFalse,
    );
  });

  test('completed status finished after endsAt', () {
    final endsAt = DateTime.now()
        .toUtc()
        .subtract(const Duration(seconds: 5))
        .toIso8601String();
    expect(
      livePkBattleFinished(
        status: 'completed',
        battle: {'endsAt': endsAt},
      ),
      isTrue,
    );
  });

  test('completed without timing info still finished', () {
    expect(livePkBattleFinished(status: 'completed', battle: const {}), isTrue);
  });
}
