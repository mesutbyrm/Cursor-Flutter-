import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/dio_provider.dart';
import '../../data/datasources/weekly_broadcaster_competition_remote_datasource.dart';
import '../../domain/pk/weekly_broadcaster_competition_models.dart';

final weeklyBroadcasterCompetitionRemoteProvider =
    Provider<WeeklyBroadcasterCompetitionRemoteDataSource>((ref) {
  return WeeklyBroadcasterCompetitionRemoteDataSource(ref.watch(dioProvider));
});

/// Haftalık yayıncı yarışması verileri — 10 dakika TTL cache ile.
class _WeeklyCompetitionCache {
  _WeeklyCompetitionCache(this.data, this.fetchedAt);
  final WeeklyBroadcasterCompetition? data;
  final DateTime fetchedAt;

  bool isExpired() =>
      DateTime.now().difference(fetchedAt) > const Duration(minutes: 10);
}

final weeklyBroadcasterCompetitionProvider =
    FutureProvider.autoDispose<WeeklyBroadcasterCompetition?>((ref) async {
  final lastCache = ref.watch(weeklyBroadcasterCompetitionCacheProvider);
  if (lastCache != null && !lastCache.isExpired()) {
    return lastCache.data;
  }

  final data = await ref
      .read(weeklyBroadcasterCompetitionRemoteProvider)
      .fetch();

  ref.read(weeklyBroadcasterCompetitionCacheProvider.notifier).state =
      _WeeklyCompetitionCache(data, DateTime.now());

  return data;
});

final weeklyBroadcasterCompetitionCacheProvider =
    StateProvider.autoDispose<_WeeklyCompetitionCache?>(
  (ref) => null,
);
