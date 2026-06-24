import 'package:flutter/foundation.dart';

/// Google AdMob yapılandırması — test birimleri debug/profile, üretim CI ile değiştirilebilir.
abstract final class AdMobConfig {
  /// Android uygulama kimliği (AndroidManifest meta-data ile aynı olmalı).
  static const androidAppId = 'ca-app-pub-3940256099942544~3347511713';

  /// Ödüllü reklam birimi — Google test ID (gerçek ID CI / dart-define ile).
  static String get rewardedAdUnitId {
    const prod = String.fromEnvironment(
      'ADMOB_REWARDED_UNIT_ID',
      defaultValue: '',
    );
    if (prod.isNotEmpty) return prod;
    if (kReleaseMode) {
      // Üretimde gerçek birim tanımlanana kadar test birimi (geliştirme APK).
      return 'ca-app-pub-3940256099942544/5224354917';
    }
    return 'ca-app-pub-3940256099942544/5224354917';
  }
}
