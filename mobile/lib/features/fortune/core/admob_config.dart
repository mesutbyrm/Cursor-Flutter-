import 'package:flutter/foundation.dart';

/// Google AdMob — Canlifal üretim birimleri (AdMob konsolu).
abstract final class AdMobConfig {
  /// Canlifal Android uygulama kimliği (AndroidManifest ile aynı).
  static const productionAndroidAppId =
      'ca-app-pub-1362974509433002~1394571120';

  /// Canlifal ödüllü reklam birimi (AdMob → Ödüllü).
  static const productionRewardedAdUnitId =
      'ca-app-pub-1362974509433002/8698346072';

  /// Google resmi test kimlikleri — debug/profile geliştirme.
  static const testAndroidAppId = 'ca-app-pub-3940256099942544~3347511713';
  static const testRewardedAdUnitId =
      'ca-app-pub-3940256099942544/5224354917';

  static const androidAppId = productionAndroidAppId;

  static String get rewardedAdUnitId {
    const override = String.fromEnvironment(
      'ADMOB_REWARDED_UNIT_ID',
      defaultValue: '',
    );
    if (override.isNotEmpty) return override;
    if (kDebugMode || kProfileMode) return testRewardedAdUnitId;
    return productionRewardedAdUnitId;
  }
}
