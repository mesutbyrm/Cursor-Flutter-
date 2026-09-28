import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/dio_provider.dart';
import '../../../../core/util/json_util.dart';
import '../../data/datasources/dreams_abacus_remote_datasource.dart';
import '../../domain/dream_contest.dart';

final dreamsRemoteDataSourceProvider = Provider<DreamsAbacusRemoteDataSource>(
  (ref) => DreamsAbacusRemoteDataSource(ref.watch(dioProvider)),
);

final dreamContestsProvider =
    FutureProvider.autoDispose<List<DreamContest>>((ref) async {
  final body = await ref
      .watch(dreamsRemoteDataSourceProvider)
      .fetchDreamContest(forceRefresh: true);
  final list = asJsonList(body['contests'])
      .map(DreamContest.fromJson)
      .where((c) => c.id.isNotEmpty)
      .toList();
  list.sort((a, b) {
    if (a.isEnded != b.isEnded) return a.isEnded ? 1 : -1;
    return 0;
  });
  return list;
});

final dreamContestEntriesProvider = FutureProvider.autoDispose
    .family<DreamContestEntries, String>((ref, contestId) async {
  final body = await ref
      .watch(dreamsRemoteDataSourceProvider)
      .fetchContestEntries(contestId, forceRefresh: true);
  return DreamContestEntries.fromJson(body);
});
