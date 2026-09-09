import 'package:canlifal_social/features/voice_hub/domain/pk/pk_battle_remote_models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('PkBattleRemote.resolvedSecondsLeft', () {
    test('prefers endsAt over secondsLeft', () {
      final now = DateTime.utc(2026, 9, 9, 12, 0, 0);
      final battle = PkBattleRemote(
        id: 'pk-1',
        battleType: 'voice_room',
        status: 'active',
        challengerScore: 0,
        opponentScore: 0,
        secondsLeft: 999,
        durationSeconds: 180,
        targetScore: 1000,
        endsAt: now.add(const Duration(seconds: 90)),
      );
      expect(battle.resolvedSecondsLeft(now: now), 90);
    });

    test('uses startedAt + duration when endsAt missing', () {
      final startedAt = DateTime.utc(2026, 9, 9, 12, 0, 0);
      final now = startedAt.add(const Duration(seconds: 150));
      final battle = PkBattleRemote(
        id: 'pk-2',
        battleType: 'voice_room',
        status: 'active',
        challengerScore: 0,
        opponentScore: 0,
        secondsLeft: 999,
        durationSeconds: 180,
        targetScore: 1000,
        startedAt: startedAt,
      );
      expect(battle.resolvedSecondsLeft(now: now), 30);
    });

    test('fromJson computes secondsLeft from endsAt', () {
      final endsAt =
          DateTime.now().toUtc().add(const Duration(seconds: 120)).toIso8601String();
      final battle = PkBattleRemote.fromJson({
        'id': 'pk-3',
        'status': 'active',
        'endsAt': endsAt,
        'secondsLeft': 5,
        'durationSeconds': 180,
      });
      expect(battle.secondsLeft, greaterThanOrEqualTo(115));
      expect(battle.secondsLeft, lessThanOrEqualTo(120));
      expect(battle.endsAt, isNotNull);
    });
  });
}
