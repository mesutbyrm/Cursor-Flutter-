import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/bootstrap/startup_perf.dart';
import '../../../../core/performance/app_perf_metrics.dart';
import '../../../live_psychics/presentation/providers/live_psychics_providers.dart';
import '../../../social/presentation/providers/social_providers.dart';
import '../../../feed/presentation/providers/platform_stats_providers.dart';
import 'home_providers.dart';

/// Ana sayfa üst bölüm API'lerini kademeli başlatır — ilk kare hızlı açılır.
final homeBootstrapProvider = FutureProvider<void>((ref) async {
  ref.keepAlive();
  await prefetchHomeCriticalSections(ref);
});

/// Kademeli ana sayfa prefetch — görünür bölümler önce, alt bölümler lazy.
Future<void> prefetchHomeCriticalSections(Ref ref) async {
  // Dalga 1: üstte görünen bölümler (paralel).
  await Future.wait([
    _measureFuture(ref, 'home.banners', homeBannersProvider),
    _measureFuture(ref, 'home.ticker', homeTickerProvider),
    _measureFuture(ref, 'home.homepage_buttons', homeHomepageButtonsProvider),
    _measureFuture(ref, 'home.trend_videos', homeTrendVideosProvider),
    _measureFuture(ref, 'home.live_streams', homeLiveStreamsProvider),
  ]);

  // Dalga 2: sesli oda + falcılar (kısa gecikme).
  await Future<void>.delayed(StartupPerf.homeVoiceSectionDelay);
  await Future.wait([
    _measureFuture(ref, 'home.voice_rooms', homeVoiceRoomsProvider),
    _measureFuture(ref, 'home.psychics', homeOnlinePsychicsProvider),
  ]);

  // Dalga 3: fal kartları + hikayeler + oyunlar (lazy).
  unawaited(
    Future<void>.delayed(StartupPerf.homeFortuneSectionDelay, () async {
      await Future.wait([
        _measureFuture(ref, 'home.fortune_cards', homeFortuneCardsProvider),
        _measureFuture(ref, 'home.story_rings', socialStoryRingsProvider),
        _measureFuture(ref, 'home.games', homeGamesProvider),
        _measureFuture(ref, 'home.daily_rewards', homeDailyRewardsProvider),
        _measureFuture(ref, 'home.fan_clubs', homeFanClubsProvider),
        _measureFuture(ref, 'home.celebrities', homeCelebritiesProvider),
        _measureFuture(ref, 'home.trend_topics', homeTrendTopicsProvider),
        _measureFuture(ref, 'home.blog_recent', homeBlogRecentProvider),
        _measureFuture(ref, 'home.gift_leaderboard', homeGiftLeaderboardProvider),
        _measureFuture(ref, 'home.football', homeFootballMatchesProvider),
        _measureFuture(ref, 'home.platform_stats', platformStatsProvider),
        _measureFuture(ref, 'home.displayed_psychics', homeDisplayedPsychicsProvider),
      ]);
    }),
  );

  if (kDebugMode) {
    debugPrint('[HomeBootstrap] wave-1 done; wave-2 done; wave-3 scheduled');
  }
}

Future<void> _measureFuture<T>(
  Ref ref,
  String label,
  FutureProvider<T> provider,
) async {
  final sw = Stopwatch()..start();
  try {
    await ref.read(provider.future);
    sw.stop();
    AppPerfMetrics.recordApi(label, sw.elapsedMilliseconds, statusCode: 200);
  } catch (_) {
    sw.stop();
    AppPerfMetrics.recordApi(label, sw.elapsedMilliseconds, statusCode: 0);
  }
}

/// Son ölçülen ana sayfa API süreleri (debug rapor).
List<PerfMetricEntry> homeApiTimings({int limit = 20}) {
  return AppPerfMetrics.slowest(limit: limit, group: 'api').where((e) {
    return e.name.startsWith('home.') || e.name.startsWith('/api/');
  }).toList();
}
