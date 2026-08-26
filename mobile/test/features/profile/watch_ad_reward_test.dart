import 'package:canlifal_social/core/network/api_endpoints.dart';
import 'package:canlifal_social/features/profile/domain/watch_ad_reward.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('parseWatchAdRewardAmount', () {
    test('creditsEarned ve nested data', () {
      expect(parseWatchAdRewardAmount({'creditsEarned': 12}), 12);
      expect(
        parseWatchAdRewardAmount({
          'data': {'reward': 8},
        }),
        8,
      );
    });

    test('bakiye yedeği ve boş gövde', () {
      expect(parseWatchAdRewardAmount({'newBalance': 40}), 40);
      expect(parseWatchAdRewardAmount({}), 0);
      expect(parseWatchAdRewardAmount(null), 0);
    });
  });

  test('kılavuz duyuru ve gelişmiş arama uçları', () {
    expect(ApiEndpoints.announcements, '/api/announcements');
    expect(ApiEndpoints.adsReward, '/api/ads/reward');
    expect(ApiEndpoints.userWatchAd, '/api/user/watch-ad');
    expect(
      ApiEndpoints.searchAdvanced(query: 'ali', type: 'user'),
      '/api/search/advanced?q=ali&type=user',
    );
  });
}
