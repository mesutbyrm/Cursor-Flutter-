import 'package:dio/dio.dart';

import '../core/network/api_endpoints.dart';
import '../core/network/dio_provider.dart';
import '../core/util/json_util.dart';
import 'service_utils.dart';

/// Oyun API — kılavuz + `FLUTTER_API_DOCS.md`.
class GameService {
  GameService({required Dio Function() resolveAuthedDio})
      : _resolveAuthedDio = resolveAuthedDio;

  final Dio Function() _resolveAuthedDio;
  Dio get _dio => _resolveAuthedDio();

  /// `GET /api/games`
  Future<List<Map<String, dynamic>>> getGames() async {
    final res = await _dio.safeGet<dynamic>(ApiEndpoints.homeGames);
    return ServiceUtils.extractList(
      res.data,
      keys: const ['games', 'items', 'data'],
    );
  }

  /// `POST /api/games/play`
  Future<Map<String, dynamic>> play({
    required String gameId,
    Map<String, dynamic>? payload,
  }) async {
    final res = await _dio.safePost<dynamic>(
      ApiEndpoints.gamePlay,
      data: {
        'gameId': gameId,
        ...?payload,
      },
    );
    return ServiceUtils.unwrapMap(res.data) ?? asJsonMap(res.data);
  }

  /// `POST /api/games/daily-spin`
  Future<Map<String, dynamic>> dailySpin() async {
    final res = await _dio.safePost<dynamic>(ApiEndpoints.gamesDailySpin);
    return ServiceUtils.unwrapMap(res.data) ?? asJsonMap(res.data);
  }

  /// `GET /api/games/quests`
  Future<List<Map<String, dynamic>>> getQuests() async {
    final res = await _dio.safeGet<dynamic>(ApiEndpoints.gamesQuests);
    return ServiceUtils.extractList(
      res.data,
      keys: const ['quests', 'missions', 'items', 'data'],
    );
  }

  /// `POST /api/games/quests` veya `.../quests/{id}`
  Future<Map<String, dynamic>> completeQuest(String id) async {
    try {
      final res = await _dio.safePost<dynamic>(
        ApiEndpoints.gamesQuestComplete(id),
        data: const {'action': 'complete'},
      );
      return ServiceUtils.unwrapMap(res.data) ?? asJsonMap(res.data);
    } catch (_) {
      final res = await _dio.safePost<dynamic>(
        ApiEndpoints.gamesQuests,
        data: {'questId': id, 'action': 'complete'},
      );
      return ServiceUtils.unwrapMap(res.data) ?? asJsonMap(res.data);
    }
  }
}
