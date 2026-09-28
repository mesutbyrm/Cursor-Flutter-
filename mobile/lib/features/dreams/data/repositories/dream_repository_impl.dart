import '../../domain/entities/dream_contest_entity.dart';
import '../../domain/repositories/dream_repository.dart';
import '../datasources/dreams_abacus_remote_datasource.dart';

class DreamRepositoryImpl implements DreamRepository {
  final DreamDataSource _dataSource;

  DreamRepositoryImpl({required DreamDataSource dataSource})
      : _dataSource = dataSource;

  @override
  Future<DreamContest> getDreamContest() async {
    final dto = await _dataSource.getDreamContest();
    return dto.toDomain();
  }

  @override
  Future<List<DreamContestEntry>> getContestEntries(String contestId) async {
    final dtos = await _dataSource.getContestEntries(contestId);
    return dtos.map((dto) => dto.toDomain()).toList();
  }

  @override
  Future<DreamContestEntry> postContestEntry(
    String contestId,
    String dreamText,
  ) async {
    final dto = await _dataSource.postContestEntry(contestId, dreamText);
    return dto.toDomain();
  }

  @override
  Future<void> voteContestEntry(String contestId, String entryId) async {
    await _dataSource.voteContestEntry(contestId, entryId);
  }

  @override
  Future<List<DreamInterpretation>> getDreamInterpretations(
    String dream,
  ) async {
    final dtos = await _dataSource.interpretDream(dream);
    return dtos.map((dto) => dto.toDomain()).toList();
  }

  @override
  Future<DreamInterpretation> getDreamSymbolInterpretation(
    String symbol,
  ) async {
    final dto = await _dataSource.getDreamSymbolInterpretation(symbol);
    return dto.toDomain();
  }
}
