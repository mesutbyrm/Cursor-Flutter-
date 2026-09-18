import 'package:canlifal_social/features/live/domain/pk/live_pk_refresh_stale_guard.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final now = DateTime.utc(2026, 9, 18, 12, 0, 0);
  const activeBattle = {
    'status': 'active',
    'id': 'pk-1',
    'liveStreamId': 's-host',
    'opponentLiveStreamId': 's-opp',
  };

  test('retains active battle within TTL when refresh empty', () {
    expect(
      shouldRetainPkBattleOnEmptyRefresh(
        battle: activeBattle,
        status: 'active',
        lastAuthorityAt: now.subtract(const Duration(seconds: 10)),
        now: now,
      ),
      isTrue,
    );
  });

  test('does not retain active battle after TTL when dual streams missing', () {
    expect(
      shouldRetainPkBattleOnEmptyRefresh(
        battle: const {
          'status': 'active',
          'id': 'pk-1',
        },
        status: 'active',
        lastAuthorityAt: now.subtract(const Duration(seconds: 120)),
        now: now,
      ),
      isFalse,
    );
  });

  test('retains pending invite without authority timestamp', () {
    expect(
      shouldRetainPkBattleOnEmptyRefresh(
        battle: const {'status': 'pending', 'id': 'pk-2'},
        status: 'pending',
        lastAuthorityAt: null,
        now: now,
      ),
      isTrue,
    );
  });

  test('retains broadcast stage even if status alone ambiguous', () {
    expect(
      shouldRetainPkBattleOnEmptyRefresh(
        battle: {
          'status': 'active',
          'liveStreamId': 'a',
          'opponentLiveStreamId': 'b',
        },
        status: 'active',
        lastAuthorityAt: null,
        now: now,
      ),
      isTrue,
    );
  });
}
