import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/cfc_arena_context.dart';
import '../../domain/cfc_arena_contest_filters.dart';
import '../../data/cfc_arena_repository.dart';

final cfcArenaContestsProvider =
    FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  return ref.read(cfcArenaRepositoryProvider).fetchPublicContests();
});

final adminCfcArenaContestsProvider =
    FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  return ref.read(cfcArenaRepositoryProvider).fetchAdminContests();
});

final cfcArenaContestsForSurfaceProvider = FutureProvider.autoDispose
    .family<List<Map<String, dynamic>>, CfcArenaSurface>((ref, surface) async {
  final all = await ref.watch(cfcArenaContestsProvider.future);
  return filterContestsForSurface(all, surface);
});
