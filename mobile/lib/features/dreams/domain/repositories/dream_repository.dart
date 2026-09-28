import '../entities/dream_contest_entity.dart';

abstract class DreamRepository {
  Future<DreamContest> getDreamContest();
  Future<List<DreamContestEntry>> getContestEntries(String contestId);
  Future<DreamContestEntry> postContestEntry(
    String contestId,
    String dreamText,
  );
  Future<void> voteContestEntry(String contestId, String entryId);
  Future<List<DreamInterpretation>> getDreamInterpretations(String dream);
  Future<DreamInterpretation> getDreamSymbolInterpretation(String symbol);
}
