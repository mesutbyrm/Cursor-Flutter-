import 'package:flutter/foundation.dart';

/// Google AdMob yapılandırması.
///
/// Reklam birimi AdMob'da **ödüllü geçiş reklamı** (Rewarded Interstitial)
/// olarak oluşturuldu → `RewardedInterstitialAd` ile yüklenmeli.
/// Debug/profile derlemelerde Google'ın resmi test birimi kullanılır
/// (kendi reklamınıza tıklamak AdMob politikası ihlalidir).
abstract final class AdMobConfig {
  /// Android uygulama kimliği (AndroidManifest meta-data ile aynı olmalı).
  static const androidAppId = 'ca-app-pub-1362974509433002~1394571120';

  /// Üretim ödüllü geçiş reklamı birimi.
  static const _prodRewardedInterstitialUnitId =
      'ca-app-pub-1362974509433002/8698346072';

  /// Google resmi test birimi — ödüllü geçiş reklamı.
  static const _testRewardedInterstitialUnitId =
      'ca-app-pub-3940256099942544/5354046379';

  /// Ödüllü geçiş reklamı birimi. `--dart-define=ADMOB_REWARDED_UNIT_ID=...`
  /// verilirse o kullanılır.
  static String get rewardedAdUnitId {
    const override = String.fromEnvironment(
      'ADMOB_REWARDED_UNIT_ID',
      defaultValue: '',
    );
    if (override.isNotEmpty) return override;
    return kReleaseMode
        ? _prodRewardedInterstitialUnitId
        : _testRewardedInterstitialUnitId;
  }
}
