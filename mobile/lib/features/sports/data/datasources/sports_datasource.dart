import 'package:dio/dio.dart';

import '../../../../core/network/api_endpoints.dart';
import '../../../../core/util/json_util.dart';
import '../models/sports_prediction_dto.dart';

abstract class SportsDataSource {
  Future<List<FootballMatchDTO>> getFootballMatches();
  Future<FootballMatchDTO> getMatchDetail(String matchId);
  Future<BetDTO> placeBet(String matchId, String prediction, double amount);
  Future<List<BetDTO>> getUserBets();
  Future<List<LeaderboardEntryDTO>> getLeaderboard({int limit = 50});
  Future<void> cancelBet(String betId);
}

class SportsDataSourceImpl implements SportsDataSource {
  final Dio _dio;

  SportsDataSourceImpl({required Dio dio}) : _dio = dio;

  @override
  Future<List<FootballMatchDTO>> getFootballMatches() async {
    final res = await _dio.safeGet<dynamic>(ApiEndpoints.football);
    final data = asJsonMap(res.data);
    final matches = (data['matches'] as List<dynamic>?)
            ?.map((e) => FootballMatchDTO.fromJson(
                e is Map<String, dynamic> ? e : asJsonMap(e)))
            .toList() ??
        [];
    return matches;
  }

  @override
  Future<FootballMatchDTO> getMatchDetail(String matchId) async {
    final res = await _dio.safeGet<dynamic>('${ApiEndpoints.football}/$matchId');
    final data = asJsonMap(res.data);
    return FootballMatchDTO.fromJson(data);
  }

  @override
  Future<BetDTO> placeBet(
    String matchId,
    String prediction,
    double amount,
  ) async {
    final res = await _dio.safePost<dynamic>(
      '${ApiEndpoints.football}/$matchId/bet',
      data: {
        'prediction': prediction,
        'amount': amount,
      },
    );
    final data = asJsonMap(res.data);
    return BetDTO.fromJson(data);
  }

  @override
  Future<List<BetDTO>> getUserBets() async {
    final res = await _dio.safeGet<dynamic>('${ApiEndpoints.football}/bets');
    final data = asJsonMap(res.data);
    final bets = (data['bets'] as List<dynamic>?)
            ?.map((e) => BetDTO.fromJson(
                e is Map<String, dynamic> ? e : asJsonMap(e)))
            .toList() ??
        [];
    return bets;
  }

  @override
  Future<List<LeaderboardEntryDTO>> getLeaderboard({int limit = 50}) async {
    final res = await _dio.safeGet<dynamic>(
      '${ApiEndpoints.football}/leaderboard?limit=$limit',
    );
    final data = asJsonMap(res.data);
    final entries = (data['leaderboard'] as List<dynamic>?)
            ?.map((e) => LeaderboardEntryDTO.fromJson(
                e is Map<String, dynamic> ? e : asJsonMap(e)))
            .toList() ??
        [];
    return entries;
  }

  @override
  Future<void> cancelBet(String betId) async {
    await _dio.safePost<dynamic>(
      '${ApiEndpoints.football}/bets/$betId/cancel',
    );
  }
}
