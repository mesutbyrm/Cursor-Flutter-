import 'package:dio/dio.dart';

import '../../../../core/network/api_endpoints.dart';
import '../../../../core/network/dio_provider.dart';
import '../../../../core/util/json_util.dart';

/// Abacus zip §4 — rüya dünyası ve rüya yarışması uçları.
class DreamsAbacusRemoteDataSource {
  DreamsAbacusRemoteDataSource(this._dio);

  final Dio _dio;

  Future<Map<String, dynamic>> fetchDreamContest() async {
    final res = await _dio.safeGet<dynamic>(ApiEndpoints.dreamContest);
    return asJsonMap(res.data);
  }

  Future<Map<String, dynamic>> fetchContestEntries(String contestId) async {
    final res = await _dio.safeGet<dynamic>(
      ApiEndpoints.dreamContestEntries(contestId),
    );
    return asJsonMap(res.data);
  }

  Future<Map<String, dynamic>> postContestEntry(
    String contestId,
    Map<String, dynamic> body,
  ) async {
    final res = await _dio.safePost<dynamic>(
      ApiEndpoints.dreamContestEntries(contestId),
      data: body,
    );
    return asJsonMap(res.data);
  }

  Future<Map<String, dynamic>> voteContest(
    String contestId,
    Map<String, dynamic> body,
  ) async {
    final res = await _dio.safePost<dynamic>(
      ApiEndpoints.dreamContestVote(contestId),
      data: body,
    );
    return asJsonMap(res.data);
  }

  Future<Map<String, dynamic>> fetchDreamFavorites() async {
    final res = await _dio.safeGet<dynamic>(ApiEndpoints.dreamsFavorites);
    return asJsonMap(res.data);
  }

  Future<Map<String, dynamic>> fetchDreamRecommendations() async {
    final res = await _dio.safeGet<dynamic>(ApiEndpoints.dreamsRecommendations);
    return asJsonMap(res.data);
  }

  Future<Map<String, dynamic>> interpretDream(Map<String, dynamic> body) async {
    final res = await _dio.safePost<dynamic>(
      ApiEndpoints.dreamsInterpret,
      data: body,
    );
    return asJsonMap(res.data);
  }

  Future<Map<String, dynamic>> fetchDreamFavorite(String slug) async {
    final res = await _dio.safeGet<dynamic>(ApiEndpoints.dreamSlugFavorite(slug));
    return asJsonMap(res.data);
  }

  Future<Map<String, dynamic>> postDreamFavorite(
    String slug,
    Map<String, dynamic> body,
  ) async {
    final res = await _dio.safePost<dynamic>(
      ApiEndpoints.dreamSlugFavorite(slug),
      data: body,
    );
    return asJsonMap(res.data);
  }

  Future<Map<String, dynamic>> postDreamView(
    String slug,
    Map<String, dynamic> body,
  ) async {
    final res = await _dio.safePost<dynamic>(
      ApiEndpoints.dreamSlugView(slug),
      data: body,
    );
    return asJsonMap(res.data);
  }
}
