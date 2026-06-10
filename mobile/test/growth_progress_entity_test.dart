import 'package:flutter_test/flutter_test.dart';

import 'package:canlifal_social/features/home/domain/entities/home_game_entity.dart';
import 'package:canlifal_social/features/profile/domain/entities/growth_progress_entity.dart';
import 'package:canlifal_social/features/profile/domain/entities/profile_stats_entity.dart';

void main() {
  group('GrowthProgressEntity', () {
    test('builds level, task and badge progress from existing signals', () {
      final progress = GrowthProgressEntity.fromSignals(
        stats: const ProfileStatsEntity(
          liveStreams: 1,
          likes: 20,
          followers: 12,
          following: 4,
          giftsReceivedCount: 3,
          giftsReceivedCoins: 500,
        ),
        dailyRewards: const [
          DailyRewardEntity(
            id: 'day-1',
            title: 'Gün 1',
            claimed: true,
            rewardJeton: 5,
          ),
        ],
        invitedCount: 1,
        hasPremium: true,
      );

      expect(progress.xp, greaterThan(500));
      expect(progress.level, greaterThanOrEqualTo(2));
      expect(progress.levelProgress, inInclusiveRange(0, 1));
      expect(progress.completedTaskCount, greaterThanOrEqualTo(4));
      expect(progress.unlockedBadgeCount, greaterThanOrEqualTo(5));
    });

    test('clamps task progress for incomplete users', () {
      final progress = GrowthProgressEntity.fromSignals(
        stats: const ProfileStatsEntity(),
        dailyRewards: const [],
      );

      expect(progress.level, 1);
      expect(progress.levelProgress, 0);
      expect(progress.tasks.first.progress, 0);
      expect(progress.tasks.first.isComplete, isFalse);
      expect(progress.badges.where((b) => b.unlocked), isEmpty);
    });
  });
}
