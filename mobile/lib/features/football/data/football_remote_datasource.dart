import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_endpoints.dart';
import '../../../core/network/dio_provider.dart';
import '../../../core/util/json_util.dart';
import '../domain/football_models.dart';

final footballRemoteDataSourceProvider = Provider<FootballRemoteDataSource>(
  (ref) => FootballRemoteDataSource(ref.watch(dioProvider)),
);

/// `GET /api/football?action=matches|standings|scorers` (football-data.org vekili).
class FootballRemoteDataSource {
  FootballRemoteDataSource(this._dio);

  final Dio _dio;

  Future<Map<String, dynamic>> _get(Map<String, dynamic> query) async {
    final res = await _dio.safeGet<dynamic>(ApiEndpoints.football, query: query);
    return asJsonMap(res.data);
  }

  static String _date(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  Future<List<FootballMatch>> matches(DateTime day) async {
    final date = _date(day);
    final body = await _get({'action': 'matches', 'dateFrom': date, 'dateTo': date});
    return asJsonList(body['matches']).map(FootballMatch.fromJson).toList();
  }

  Future<List<FootballStandingRow>> standings(String competition) async {
    final body = await _get({'action': 'standings', 'competition': competition});
    return FootballStandingRow.fromStandings(body['standings']);
  }

  Future<List<FootballScorer>> scorers(String competition) async {
    final body = await _get({'action': 'scorers', 'competition': competition});
    return asJsonList(body['scorers']).map(FootballScorer.fromJson).toList();
  }
}

final footballMatchesProvider = FutureProvider.autoDispose
    .family<List<FootballMatch>, DateTime>(
  (ref, day) => ref.watch(footballRemoteDataSourceProvider).matches(day),
);

final footballStandingsProvider = FutureProvider.autoDispose
    .family<List<FootballStandingRow>, String>(
  (ref, code) => ref.watch(footballRemoteDataSourceProvider).standings(code),
);

final footballScorersProvider = FutureProvider.autoDispose
    .family<List<FootballScorer>, String>(
  (ref, code) => ref.watch(footballRemoteDataSourceProvider).scorers(code),
);
