import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/datasources/dreams_abacus_remote_datasource.dart';
import '../../data/repositories/dream_repository_impl.dart';
import '../../domain/entities/dream_contest_entity.dart';
import '../../domain/repositories/dream_repository.dart';
import '../../../../core/network/dio_provider.dart';

final dreamDataSourceProvider = Provider<DreamDataSource>((ref) {
  final dio = ref.watch(dioProvider);
  return DreamDataSourceImpl(dio: dio);
});

final dreamRepositoryProvider = Provider<DreamRepository>((ref) {
  final dataSource = ref.watch(dreamDataSourceProvider);
  return DreamRepositoryImpl(dataSource: dataSource);
});

final dreamContestProvider = FutureProvider<DreamContest>((ref) async {
  final repository = ref.watch(dreamRepositoryProvider);
  return repository.getDreamContest();
});

final contestEntriesProvider =
    FutureProvider.family<List<DreamContestEntry>, String>((ref, contestId) async {
  final repository = ref.watch(dreamRepositoryProvider);
  return repository.getContestEntries(contestId);
});

final dreamInterpretationProvider = FutureProvider.family<
    List<DreamInterpretation>,
    String>((ref, dreamText) async {
  final repository = ref.watch(dreamRepositoryProvider);
  return repository.getDreamInterpretations(dreamText);
});

final symbolInterpretationProvider =
    FutureProvider.family<DreamInterpretation, String>((ref, symbol) async {
  final repository = ref.watch(dreamRepositoryProvider);
  return repository.getDreamSymbolInterpretation(symbol);
});

final selectedContestEntryProvider =
    StateProvider<DreamContestEntry?>((ref) => null);

final votedEntriesProvider =
    StateProvider<Set<String>>((ref) => {});
