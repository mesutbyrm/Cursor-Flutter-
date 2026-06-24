import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../../core/admob_config.dart';

/// AdMob ödüllü reklam — tam izlenince `true`, yarıda kapanınca `false`.
class RewardedAdService {
  RewardedAdService._();

  static final RewardedAdService instance = RewardedAdService._();

  static bool _sdkReady = false;
  RewardedAd? _ad;
  bool _loading = false;

  static Future<void> ensureInitialized() async {
    if (kIsWeb) return;
    if (_sdkReady) return;
    await MobileAds.instance.initialize();
    _sdkReady = true;
  }

  Future<void> preload() async {
    if (kIsWeb) return;
    await ensureInitialized();
    if (_ad != null || _loading) return;
    _loading = true;
    try {
      await RewardedAd.load(
        adUnitId: AdMobConfig.rewardedAdUnitId,
        request: const AdRequest(),
        rewardedAdLoadCallback: RewardedAdLoadCallback(
          onAdLoaded: (ad) {
            _ad = ad;
            _loading = false;
          },
          onAdFailedToLoad: (_) {
            _ad = null;
            _loading = false;
          },
        ),
      );
    } catch (_) {
      _loading = false;
    }
  }

  /// Reklamı gösterir. Ödül kazanıldıysa `true`.
  Future<bool> show() async {
    if (kIsWeb) return false;
    await ensureInitialized();
    await preload();

    final ad = _ad;
    if (ad == null) return false;

    final completer = Completer<bool>();
    var rewarded = false;

    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (d) {
        d.dispose();
        _ad = null;
        preload();
        if (!completer.isCompleted) completer.complete(rewarded);
      },
      onAdFailedToShowFullScreenContent: (d, _) {
        d.dispose();
        _ad = null;
        preload();
        if (!completer.isCompleted) completer.complete(false);
      },
    );

    await ad.show(
      onUserEarnedReward: (_, __) {
        rewarded = true;
      },
    );

    return completer.future.timeout(
      const Duration(minutes: 3),
      onTimeout: () => rewarded,
    );
  }
}
