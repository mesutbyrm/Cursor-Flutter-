import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../../core/admob_config.dart';

/// AdMob ödüllü geçiş reklamı — tam izlenince `true`, yarıda kapanınca `false`.
class RewardedAdService {
  RewardedAdService._();

  static final RewardedAdService instance = RewardedAdService._();

  static bool _sdkReady = false;
  RewardedInterstitialAd? _ad;
  bool _loading = false;

  static Future<void> ensureInitialized() async {
    if (kIsWeb) return;
    if (_sdkReady) return;
    await MobileAds.instance.initialize();
    _sdkReady = true;
  }

  Future<void> preload({Duration timeout = const Duration(seconds: 15)}) async {
    if (kIsWeb) return;
    await ensureInitialized();
    if (_ad != null) return;
    if (_loading) {
      final deadline = DateTime.now().add(timeout);
      while (_loading && _ad == null && DateTime.now().isBefore(deadline)) {
        await Future<void>.delayed(const Duration(milliseconds: 200));
      }
      return;
    }
    _loading = true;
    try {
      final completer = Completer<void>();
      await RewardedInterstitialAd.load(
        adUnitId: AdMobConfig.rewardedAdUnitId,
        request: const AdRequest(),
        rewardedInterstitialAdLoadCallback: RewardedInterstitialAdLoadCallback(
          onAdLoaded: (ad) {
            _ad = ad;
            _loading = false;
            if (!completer.isCompleted) completer.complete();
          },
          onAdFailedToLoad: (error) {
            debugPrint('AdMob yüklenemedi: ${error.code} ${error.message}');
            _ad = null;
            _loading = false;
            if (!completer.isCompleted) completer.complete();
          },
        ),
      );
      await completer.future.timeout(timeout, onTimeout: () {});
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
      onUserEarnedReward: (_, _) {
        rewarded = true;
      },
    );

    return completer.future.timeout(
      const Duration(minutes: 3),
      onTimeout: () => rewarded,
    );
  }
}
