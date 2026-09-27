import 'package:canlifal_social/features/fortune/core/admob_config.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('production AdMob app id matches manifest constant', () {
    expect(
      AdMobConfig.androidAppId,
      'ca-app-pub-1362974509433002~1394571120',
    );
    expect(
      AdMobConfig.productionRewardedInterstitialAdUnitId,
      'ca-app-pub-1362974509433002/8698346072',
    );
  });
}
