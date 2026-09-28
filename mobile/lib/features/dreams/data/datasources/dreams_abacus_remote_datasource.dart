import 'package:dio/dio.dart';

import '../../../../core/network/api_endpoints.dart';
import '../../../../core/network/dio_provider.dart';
import '../../../../core/util/json_util.dart';
import '../models/dream_contest_dto.dart';

abstract class DreamDataSource {
  Future<DreamContestDTO> getDreamContest();
  Future<List<DreamContestEntryDTO>> getContestEntries(String contestId);
  Future<DreamContestEntryDTO> postContestEntry(
    String contestId,
    String dreamText,
  );
  Future<void> voteContestEntry(String contestId, String entryId);
  Future<List<DreamInterpretationDTO>> interpretDream(String dreamText);
  Future<DreamInterpretationDTO> getDreamSymbolInterpretation(String symbol);
}

class DreamDataSourceImpl implements DreamDataSource {
  final Dio _dio;

  DreamDataSourceImpl({required Dio dio}) : _dio = dio;

  @override
  Future<DreamContestDTO> getDreamContest() async {
    final res = await _dio.safeGet<dynamic>(ApiEndpoints.dreamContest);
    final data = asJsonMap(res.data);
    return DreamContestDTO.fromJson(data);
  }

  @override
  Future<List<DreamContestEntryDTO>> getContestEntries(String contestId) async {
    final res = await _dio.safeGet<dynamic>(
      ApiEndpoints.dreamContestEntries(contestId),
    );
    final data = asJsonMap(res.data);
    final entries = (data['entries'] as List<dynamic>?)
            ?.map((e) => DreamContestEntryDTO.fromJson(
                e is Map<String, dynamic> ? e : asJsonMap(e)))
            .toList() ??
        [];
    return entries;
  }

  @override
  Future<DreamContestEntryDTO> postContestEntry(
    String contestId,
    String dreamText,
  ) async {
    final res = await _dio.safePost<dynamic>(
      ApiEndpoints.dreamContestEntries(contestId),
      data: {'dreamText': dreamText},
    );
    final data = asJsonMap(res.data);
    return DreamContestEntryDTO.fromJson(data);
  }

  @override
  Future<void> voteContestEntry(String contestId, String entryId) async {
    await _dio.safePost<dynamic>(
      ApiEndpoints.dreamContestVote(contestId),
      data: {'entryId': entryId},
    );
  }

  @override
  Future<List<DreamInterpretationDTO>> interpretDream(String dreamText) async {
    final res = await _dio.safePost<dynamic>(
      ApiEndpoints.dreamsInterpret,
      data: {'dream': dreamText},
    );
    final data = asJsonMap(res.data);
    final interpretations = (data['interpretations'] as List<dynamic>?)
            ?.map((e) => DreamInterpretationDTO.fromJson(
                e is Map<String, dynamic> ? e : asJsonMap(e)))
            .toList() ??
        [];
    return interpretations;
  }

  @override
  Future<DreamInterpretationDTO> getDreamSymbolInterpretation(
    String symbol,
  ) async {
    final res = await _dio.safeGet<dynamic>(
      '${ApiEndpoints.dreamSymbols}/$symbol',
    );
    final data = asJsonMap(res.data);
    return DreamInterpretationDTO.fromJson(data);
  }
}
