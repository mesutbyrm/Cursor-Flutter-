import 'package:dio/dio.dart';

import '../../../core/network/api_endpoints.dart';
import '../../../core/network/dio_provider.dart';
import '../../../core/util/json_util.dart';
import '../domain/game_models.dart';

class GameRemoteDataSource {
  GameRemoteDataSource(this._dio);

  final Dio _dio;

  Future<List<GameCatalogItem>> fetchCatalog() async {
    try {
      final res = await _dio.safeGet<dynamic>(ApiEndpoints.homeGames);
      final items =
          _items(res.data, const ['games', 'items', 'data', 'results'])
              .map(GameCatalogItem.fromJson)
              .where((item) => item.id.isNotEmpty)
              .toList();
      if (items.isNotEmpty) return _mergeWithFallback(items);
    } catch (_) {}
    return GameCatalogFallback.all;
  }

  Future<List<GameRoomItem>> fetchRooms() async {
    try {
      final res = await _dio.safeGet<dynamic>(ApiEndpoints.gameRooms);
      return _items(
        res.data,
        const ['rooms', 'items', 'data', 'results'],
      ).map(GameRoomItem.fromJson).where((room) => room.id.isNotEmpty).toList();
    } catch (_) {
      return const [];
    }
  }

  Future<GameRoomItem?> createRoom(GameCatalogItem game) async {
    final res = await _dio.safePost<dynamic>(
      ApiEndpoints.gameRooms,
      data: {
        'gameId': game.id,
        'type': game.id,
        'slug': game.id,
        'title': game.title,
        if (game.jetonCost > 0) 'jetonCost': game.jetonCost,
      },
    );
    return _roomFromBody(res.data);
  }

  Future<GameRoomItem?> autoMatch(GameCatalogItem game) async {
    final res = await _dio.safePost<dynamic>(
      ApiEndpoints.gameAutoMatch,
      data: {'gameId': game.id, 'type': game.id, 'slug': game.id},
    );
    return _roomFromBody(res.data);
  }

  Future<GameRoomItem?> joinRoom(String roomId) async {
    final res = await _dio.safePost<dynamic>(ApiEndpoints.gameRoomJoin(roomId));
    return _roomFromBody(res.data);
  }

  Future<GameRoomStateSnapshot> fetchRoomState(String roomId) async {
    try {
      final res = await _dio.safePost<dynamic>(
        ApiEndpoints.gameRoom(roomId),
        data: const {'action': 'state'},
      );
      return GameRoomStateSnapshot.fromJson(roomId, _map(res.data));
    } catch (_) {
      return GameRoomStateSnapshot(roomId: roomId, status: 'unknown');
    }
  }

  Future<GameRoomStateSnapshot> sendMove({
    required String roomId,
    required Map<String, dynamic> move,
  }) async {
    final res = await _dio.safePost<dynamic>(
      ApiEndpoints.gameRoom(roomId),
      data: {'action': 'move', 'move': move, ...move},
    );
    return GameRoomStateSnapshot.fromJson(roomId, _map(res.data));
  }

  Future<void> sendChat({required String roomId, required String text}) async {
    final message = text.trim();
    if (message.isEmpty) return;
    await _dio.safePost<dynamic>(
      ApiEndpoints.gameRoomChat(roomId),
      data: {'message': message, 'text': message, 'content': message},
    );
  }

  Future<List<GameScoreItem>> fetchLeaderboard() async {
    try {
      final res = await _dio.safePost<dynamic>(ApiEndpoints.gameLeaderboard);
      return _scores(res.data);
    } catch (_) {
      return const [];
    }
  }

  Future<List<GameScoreItem>> fetchHistory() async {
    try {
      final res = await _dio.safeGet<dynamic>(ApiEndpoints.gameHistory);
      return _scores(res.data);
    } catch (_) {
      return const [];
    }
  }

  Future<List<GameScoreItem>> fetchMiniScores() async {
    try {
      final res = await _dio.safeGet<dynamic>(ApiEndpoints.gameMiniScores);
      return _scores(res.data);
    } catch (_) {
      return const [];
    }
  }

  Future<List<GameScoreItem>> fetchProfileScores() async {
    try {
      final res = await _dio.safeGet<dynamic>(ApiEndpoints.gameProfile);
      return _scores(res.data);
    } catch (_) {
      return const [];
    }
  }

  Future<void> saveMiniScore({
    required String gameId,
    required int score,
  }) async {
    await _dio.safePost<dynamic>(
      ApiEndpoints.gameMiniScores,
      data: {'gameId': gameId, 'score': score},
    );
  }

  Future<List<GameScoreItem>> fetchTournaments() async {
    try {
      final res = await _dio.safeGet<dynamic>(ApiEndpoints.tournaments);
      return _scores(res.data);
    } catch (_) {
      return const [];
    }
  }

  Future<void> joinTournament(String tournamentId) async {
    await _dio.safePost<dynamic>(
      ApiEndpoints.tournamentsJoin,
      data: {'tournamentId': tournamentId, 'id': tournamentId},
    );
  }

  GameRoomItem? _roomFromBody(dynamic body) {
    final map = _map(body);
    final raw = pick(map, ['room', 'gameRoom', 'data', 'match']) ?? map;
    if (raw is Map) {
      final room = GameRoomItem.fromJson(asJsonMap(raw));
      if (room.id.isNotEmpty) return room;
    }
    return null;
  }

  List<GameScoreItem> _scores(dynamic body) {
    return _items(body, const [
      'items',
      'scores',
      'leaderboard',
      'history',
      'entries',
      'results',
      'data',
    ]).map(GameScoreItem.fromJson).toList();
  }

  List<Map<String, dynamic>> _items(dynamic body, List<String> keys) {
    if (body is List) return asJsonList(body);
    if (body is! Map) return const [];
    final map = asJsonMap(body);
    if (map['success'] == true && map['data'] != null) {
      return _items(map['data'], keys);
    }
    for (final key in keys) {
      final raw = map[key];
      if (raw is List) return asJsonList(raw);
      if (raw is Map) {
        final nested = _items(raw, keys);
        if (nested.isNotEmpty) return nested;
      }
    }
    if (map['id'] != null || map['roomId'] != null) return [map];
    return const [];
  }

  Map<String, dynamic> _map(dynamic body) {
    if (body is Map) {
      final map = asJsonMap(body);
      if (map['success'] == true && map['data'] is Map) {
        return asJsonMap(map['data']);
      }
      return map;
    }
    return const {};
  }

  List<GameCatalogItem> _mergeWithFallback(List<GameCatalogItem> remote) {
    final byId = {for (final item in remote) item.id: item};
    for (final item in GameCatalogFallback.all) {
      byId.putIfAbsent(item.id, () => item);
    }
    return byId.values.toList();
  }
}
