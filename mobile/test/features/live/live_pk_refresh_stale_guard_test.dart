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

  // `paused` bitmiş değil devam eden bir maçtır (`PkStatus.isLive`,
  // pk_models.dart). Guard bunu kapsamadığı için duraklatılmış maç boş
  // refresh'te siliniyordu — `active` ile aynı şekilde korunmalı.
  group('paused', () {
    test('retains paused battle within TTL when refresh empty', () {
      expect(
        shouldRetainPkBattleOnEmptyRefresh(
          battle: const {'status': 'paused', 'id': 'pk-3'},
          status: 'paused',
          lastAuthorityAt: now.subtract(const Duration(seconds: 10)),
          now: now,
        ),
        isTrue,
      );
    });

    test('retains paused battle with dual streams within TTL', () {
      expect(
        shouldRetainPkBattleOnEmptyRefresh(
          battle: const {
            'status': 'paused',
            'id': 'pk-3',
            'liveStreamId': 's-host',
            'opponentLiveStreamId': 's-opp',
          },
          status: 'paused',
          lastAuthorityAt: now.subtract(const Duration(seconds: 10)),
          now: now,
        ),
        isTrue,
      );
    });

    // Sınırı belgeler: paused, active ile aynı TTL davranışına tabidir.
    test('does not retain paused battle after TTL', () {
      expect(
        shouldRetainPkBattleOnEmptyRefresh(
          battle: const {'status': 'paused', 'id': 'pk-3'},
          status: 'paused',
          lastAuthorityAt: now.subtract(const Duration(seconds: 120)),
          now: now,
        ),
        isFalse,
      );
    });

    test('still clears genuinely ended battle', () {
      expect(
        shouldRetainPkBattleOnEmptyRefresh(
          battle: const {'status': 'completed', 'id': 'pk-3'},
          status: 'completed',
          lastAuthorityAt: now.subtract(const Duration(seconds: 10)),
          now: now,
        ),
        isFalse,
      );
    });
  });
}
