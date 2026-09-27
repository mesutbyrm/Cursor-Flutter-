import 'package:flutter/foundation.dart';

/// Google AdMob — Canlifal üretim birimleri (AdMob konsolu).
///
/// Birim türü: **ödüllü geçiş reklamı** (Rewarded Interstitial) →
/// `RewardedInterstitialAd` ile yüklenmeli (klasik `RewardedAd` değil).
///
/// Yayıncı doğrulama: repo kökü `app-ads.txt` → https://canlifal.com/app-ads.txt
abstract final class AdMobConfig {
  static const adsTxtPublisherId = 'pub-1362974509433002';

  /// Canlifal Android uygulama kimliği (AndroidManifest ile aynı).
  static const productionAndroidAppId =
      'ca-app-pub-1362974509433002~1394571120';

  /// Canlifal ödüllü geçiş reklamı birimi (AdMob → Ödüllü geçiş).
  static const productionRewardedInterstitialAdUnitId =
      'ca-app-pub-1362974509433002/8698346072';

  /// Google resmi test kimlikleri — debug/profile geliştirme.
  static const testAndroidAppId = 'ca-app-pub-3940256099942544~3347511713';

  /// Google resmi test — ödüllü geçiş reklamı.
  static const testRewardedInterstitialAdUnitId =
      'ca-app-pub-3940256099942544/5354046379';

  static const androidAppId = productionAndroidAppId;

  static String get rewardedAdUnitId {
    const override = String.fromEnvironment(
      'ADMOB_REWARDED_UNIT_ID',
      defaultValue: '',
    );
    if (override.isNotEmpty) return override;
    if (kDebugMode || kProfileMode) {
      return testRewardedInterstitialAdUnitId;
    }
    return productionRewardedInterstitialAdUnitId;
  }
}
