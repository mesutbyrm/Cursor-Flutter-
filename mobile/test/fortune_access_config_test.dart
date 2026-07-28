import 'package:flutter_test/flutter_test.dart';

import 'package:canlifal_social/features/fortune/domain/fortune_access_config.dart';
import 'package:canlifal_social/features/fortune/presentation/providers/fortune_access_providers.dart';

void main() {
  group('FortuneAccessConfig', () {
    test('defaults match spec (10 jeton, 1 credit per ad)', () {
      const config = FortuneAccessConfig.defaults;
      expect(config.jetonCost, 10);
      expect(config.adCreditsPerAd, 1);
      expect(config.dailyAdLimit, 20);
      expect(config.adsEnabled, isTrue);
      expect(config.premiumUnlimited, isTrue);
    });

    test('fromJson parses admin settings', () {
      final config = FortuneAccessConfig.fromJson({
        'jetonCost': 15,
        'adCreditsPerAd': 2,
        'dailyAdLimit': 5,
        'adsEnabled': false,
        'adRequired': true,
        'premiumUnlimited': false,
      });
      expect(config.jetonCost, 15);
      expect(config.adCreditsPerAd, 2);
      expect(config.dailyAdLimit, 5);
      expect(config.adsEnabled, isFalse);
      expect(config.adRequired, isTrue);
      expect(config.premiumUnlimited, isFalse);
    });
  });

  group('FortuneAccessState', () {
    test('hasEnoughJeton when balance meets cost', () {
      const state = FortuneAccessState(
        config: FortuneAccessConfig.defaults,
        adCredits: 0,
        adsWatchedToday: 0,
        jetonBalance: 10,
        cfcBalance: 0,
        isPremiumUnlimited: false,
      );
      expect(state.hasEnoughJeton, isTrue);
      expect(state.hasAdCredits, isFalse);
    });

    test('canWatchMoreAds respects daily limit', () {
      const state = FortuneAccessState(
        config: FortuneAccessConfig(dailyAdLimit: 3),
        adCredits: 0,
        adsWatchedToday: 3,
        jetonBalance: 0,
        cfcBalance: 0,
        isPremiumUnlimited: false,
      );
      expect(state.canWatchMoreAds, isFalse);
    });
  });
}
