import 'package:canlifal_social/features/live/domain/pk/live_pk_authoritative_outcome.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('uses backend winnerId for local user', () {
    final o = resolveLivePkAuthoritativeOutcome(
      battle: {
        'winnerId': 'u2',
        'user1Id': 'u1',
        'user2Id': 'u2',
        'status': 'completed',
      },
      ended: true,
      myUserId: 'u2',
      localOnLeft: false,
      leftScore: 10,
      rightScore: 20,
    );
    expect(o.usedBackendWinner, isTrue);
    expect(o.localWon, isTrue);
    expect(o.isDraw, isFalse);
  });

  test('isDraw from backend flag', () {
    final o = resolveLivePkAuthoritativeOutcome(
      battle: {'isDraw': true, 'status': 'completed'},
      ended: true,
      myUserId: 'u1',
      localOnLeft: true,
      leftScore: 100,
      rightScore: 50,
    );
    expect(o.isDraw, isTrue);
    expect(o.usedBackendWinner, isTrue);
  });

  test('falls back to score tie', () {
    final o = resolveLivePkAuthoritativeOutcome(
      battle: {'status': 'ended'},
      ended: true,
      myUserId: 'u1',
      localOnLeft: true,
      leftScore: 5,
      rightScore: 5,
    );
    expect(o.isDraw, isTrue);
    expect(o.usedBackendWinner, isFalse);
  });
}
