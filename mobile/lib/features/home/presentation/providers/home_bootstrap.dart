import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/performance/app_perf_metrics.dart';
import '../../../social/presentation/providers/social_providers.dart';
import 'home_providers.dart';

/// Ana sayfa üst bölüm API'lerini paralel başlatır — bölüm gecikmelerinden önce.
final homeBootstrapProvider = FutureProvider<void>((ref) async {
  ref.keepAlive();
  await prefetchHomeCriticalSections(ref);
});

/// Paralel ana sayfa prefetch + süre ölçümü.
Future<void> prefetchHomeCriticalSections(Ref ref) async {
  final tasks = <Future<void>>[
    _measureFuture(ref, 'home.banners', homeBannersProvider),
    _measureFuture(ref, 'home.trend_videos', homeTrendVideosProvider),
    _measureFuture(ref, 'home.live_streams', homeLiveStreamsProvider),
    _measureFuture(ref, 'home.voice_rooms', homeVoiceRoomsProvider),
    _measureFuture(ref, 'home.fortune_cards', homeFortuneCardsProvider),
    _measureFuture(ref, 'home.story_rings', socialStoryRingsProvider),
  ];
  await Future.wait(tasks);
  if (kDebugMode) {
    debugPrint(
      '[HomeBootstrap] critical sections prefetched (${tasks.length} parallel)',
    );
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
