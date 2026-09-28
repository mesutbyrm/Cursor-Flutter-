import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../../../../core/network/api_endpoints.dart';
import '../../../../core/network/dio_provider.dart';
import '../../../../core/util/json_util.dart';
import '../../domain/pk/weekly_broadcaster_competition_models.dart';

/// Haftalık yayıncı yarışması = CFC Arena'daki aktif `broadcaster` yarışması
/// (`scope: weekly` öncelikli). `GET /api/cfc-arena?status=active` →
/// `GET /api/cfc-arena/{id}` (`leaderboard`).
class WeeklyBroadcasterCompetitionRemoteDataSource {
  const WeeklyBroadcasterCompetitionRemoteDataSource(this._dio);

  final Dio _dio;

  static Map<String, dynamic>? pickContest(List<Map<String, dynamic>> contests) {
    final broadcaster =
        contests.where((c) => c['type']?.toString() == 'broadcaster').toList();
    if (broadcaster.isEmpty) return null;
    int score(Map<String, dynamic> c) =>
        (c['scope']?.toString() == 'weekly' ? 2 : 0) +
        (c['isFeatured'] == true ? 1 : 0);
    broadcaster.sort((a, b) => score(b).compareTo(score(a)));
    return broadcaster.first;
  }

  static WeeklyBroadcasterCompetition fromArenaDetail(Map<String, dynamic> data) {
    final contest = asJsonMap(data['contest']);
    final participants = [
      for (final p in asJsonList(data['leaderboard']))
        {
          'rank': p['rank'],
          'userId': p['userId'] ?? p['id'],
          'displayName':
              asJsonMap(p['user'])['name'] ?? asJsonMap(p['user'])['username'] ?? p['displayName'],
          'image': asJsonMap(p['user'])['image'],
          'score': p['score'],
        },
    ];
    return WeeklyBroadcasterCompetition.fromJson({
      'title': contest['name'],
      'startsAt': contest['startsAt'],
      'endsAt': contest['endsAt'],
      'participants': participants,
    });
  }

  Future<WeeklyBroadcasterCompetition?> fetch() async {
    try {
      final list = await _dio.safeGet<dynamic>(
        ApiEndpoints.cfcArena,
        query: {'status': 'active', 'limit': 50},
      );
      final root = asJsonMap(list.data);
      final data = root['data'] is Map ? asJsonMap(root['data']) : root;
      final contest = pickContest(asJsonList(data['contests']));
      final id = contest?['id']?.toString();
      if (id == null || id.isEmpty) return null;
      final detail = await _dio.safeGet<dynamic>(
        ApiEndpoints.cfcArenaContest(id),
        query: {'limit': 50},
      );
      final body = asJsonMap(detail.data);
      return fromArenaDetail(
        body['data'] is Map ? asJsonMap(body['data']) : body,
      );
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[WeeklyCompetition] fetch failed: $e');
      }
      return null;
    }
  }
}
