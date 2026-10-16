import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/network/dio_provider.dart';
import '../../../fortune/data/services/rewarded_ad_service.dart';

/// GirLive Sosyal akışı — her [interval] paylaşımdan sonra tam ekran
/// geçiş reklamı (AdMob Interstitial).
///
/// Birim kimliği admin panelinden gelir: Reklam Yerleşimleri →
/// `social_feed_interstitial` («Özel kod» = `ca-app-pub-…/…` veya bağlı ağın
/// birimi). Hedefleme (ör. VIP'de gizle) sunucuda; günlük sınır burada uygulanır.
class SocialFeedAdService {
  SocialFeedAdService._();

  static final SocialFeedAdService instance = SocialFeedAdService._();

  static const placementKey = 'social_feed_interstitial';
  static const interval = 5;

  static const _testUnitId = 'ca-app-pub-3940256099942544/1033173712';
  static final _unitPattern = RegExp(r'^ca-app-pub-\d+/\d+$');

  InterstitialAd? _ad;
  bool _loading = false;
  String? _unitId;
  int _frequencyCap = 0;
  DateTime? _configAt;

  /// Admin yapılandırmasından birim kimliği (30 dk önbellek).
  Future<String?> _resolveUnit(Dio dio) async {
    final at = _configAt;
    if (at != null && DateTime.now().difference(at) < const Duration(minutes: 30)) {
      return _unitId;
    }
    String? unit;
    var cap = 0;
    try {
      final res = await dio.safeGet<dynamic>(
        '/api/ads/placement',
        query: {'key': placementKey, 'platform': 'mobile'},
        forceRefresh: true,
      );
      final body = res.data;
      if (body is Map && body['hasAd'] == true && body['placement'] is Map) {
        final p = body['placement'] as Map;
        final code = p['adCode']?.toString().trim() ?? '';
        final net = p['adUnitId']?.toString().trim() ?? '';
        if (_unitPattern.hasMatch(code)) {
          unit = code;
        } else if (_unitPattern.hasMatch(net)) {
          unit = net;
        }
        cap = (p['frequencyCap'] as num?)?.toInt() ?? 0;
      }
    } catch (_) {}
    const override = String.fromEnvironment('ADMOB_SOCIAL_INTERSTITIAL_UNIT_ID');
    if (unit == null && override.isNotEmpty) unit = override;
    // Geliştirme sürümünde Google test reklamı ile akış denenebilir.
    if (unit == null && (kDebugMode || kProfileMode)) unit = _testUnitId;
    _unitId = unit;
    _frequencyCap = cap;
    _configAt = DateTime.now();
    return unit;
  }

  /// Bir sonraki reklamı arka planda hazırla.
  Future<void> preload(Dio dio) async {
    if (kIsWeb || _ad != null || _loading) return;
    final unit = await _resolveUnit(dio);
    if (unit == null) return;
    _loading = true;
    try {
      await RewardedAdService.ensureInitialized();
      final done = Completer<void>();
      await InterstitialAd.load(
        adUnitId: unit,
        request: const AdRequest(),
        adLoadCallback: InterstitialAdLoadCallback(
          onAdLoaded: (ad) {
            _ad = ad;
            if (!done.isCompleted) done.complete();
          },
          onAdFailedToLoad: (e) {
            debugPrint('Sosyal reklam yüklenemedi: ${e.code} ${e.message}');
            if (!done.isCompleted) done.complete();
          },
        ),
      );
      await done.future.timeout(const Duration(seconds: 20), onTimeout: () {});
    } catch (_) {
    } finally {
      _loading = false;
    }
  }

  Future<bool> _underDailyCap() async {
    if (_frequencyCap <= 0) return true;
    try {
      final prefs = await SharedPreferences.getInstance();
      final today = DateTime.now().toIso8601String().substring(0, 10);
      final day = prefs.getString('social_ad_day');
      final count = day == today ? (prefs.getInt('social_ad_count') ?? 0) : 0;
      return count < _frequencyCap;
    } catch (_) {
      return true;
    }
  }

  Future<void> _countShown() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final today = DateTime.now().toIso8601String().substring(0, 10);
      final day = prefs.getString('social_ad_day');
      final count = day == today ? (prefs.getInt('social_ad_count') ?? 0) : 0;
      await prefs.setString('social_ad_day', today);
      await prefs.setInt('social_ad_count', count + 1);
    } catch (_) {}
  }

  /// Hazır reklam varsa tam ekran gösterir; kapanınca tamamlanır.
  /// Gösterilemezse hemen `false` döner (akış engellenmez).
  Future<bool> showIfReady(Dio dio, {bool ignoreInterval = false}) async {
    final ad = _ad;
    if (ad == null) {
      unawaited(preload(dio));
      return false;
    }
    if (!await _underDailyCap()) return false;
    _ad = null;
    final closed = Completer<bool>();
    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdShowedFullScreenContent: (_) {
        unawaited(_countShown());
        unawaited(
          dio.safePost<dynamic>(
            '/api/ads/placement',
            data: {'key': placementKey, 'event': 'impression'},
          ).then((_) {}, onError: (_) {}),
        );
      },
      onAdClicked: (_) {
        unawaited(
          dio.safePost<dynamic>(
            '/api/ads/placement',
            data: {'key': placementKey, 'event': 'click'},
          ).then((_) {}, onError: (_) {}),
        );
      },
      onAdDismissedFullScreenContent: (a) {
        a.dispose();
        if (!closed.isCompleted) closed.complete(true);
      },
      onAdFailedToShowFullScreenContent: (a, _) {
        a.dispose();
        if (!closed.isCompleted) closed.complete(false);
      },
    );
    await ad.show();
    final shown = await closed.future;
    unawaited(preload(dio));
    return shown;
  }
}
