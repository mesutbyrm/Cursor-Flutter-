import 'package:dio/dio.dart';

import '../../../core/network/api_endpoints.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/network/dio_provider.dart';
import '../../../core/util/json_util.dart';
import '../domain/game_center_models.dart';
import '../domain/game_models.dart';

class GameRemoteDataSource {
  GameRemoteDataSource(this._dio);

  final Dio _dio;

  Future<List<GameCatalogItem>> fetchCatalog() async {
    final res = await _dio.safeGet<dynamic>(ApiEndpoints.homeGames);
    return _items(res.data, const ['games', 'items', 'data', 'results'])
        .map(GameCatalogItem.fromJson)
        .where((item) => item.id.isNotEmpty)
        .toList();
  }

  Future<List<GameRoomItem>> fetchRooms() async {
    final res = await _dio.safeGet<dynamic>(ApiEndpoints.gameRooms);
    return _parseRooms(res.data);
  }

  Future<GameRoomItem?> createRoom(GameCatalogItem game) async {
    final gameType = _gameType(game);
    final attempts = <({String path, Map<String, dynamic> data})>[
      (path: ApiEndpoints.gameRooms, data: {'gameType': gameType}),
      ..._legacyCreatePayloads(game).map(
        (data) => (path: ApiEndpoints.gameRooms, data: data),
      ),
      ..._legacyCreatePayloads(game).map(
        (data) => (path: ApiEndpoints.gameRoomCreate, data: data),
      ),
    ];

    ApiException? lastError;
    for (final attempt in attempts) {
      try {
        final res = await _dio.safePost<dynamic>(
          attempt.path,
          data: attempt.data,
        );
        final room = _roomFromBody(res.data);
        if (room != null) return room;
      } on ApiException catch (e) {
        lastError = e;
        if (e.statusCode == 404 || e.statusCode == 405) continue;
        rethrow;
      }
    }
    throw lastError ?? ApiException('Oda oluşturulamadı ($gameType)');
  }

  Future<GameRoomItem?> autoMatch(GameCatalogItem game) async {
    final gameType = _gameType(game);
    final attempts = <({String path, Map<String, dynamic> data})>[
      (path: ApiEndpoints.gameAutoMatch, data: {'gameType': gameType}),
      ..._legacyAutoMatchPayloads(game).map(
        (data) => (path: ApiEndpoints.gameAutoMatch, data: data),
      ),
      ..._legacyAutoMatchPayloads(game).map(
        (data) => (path: ApiEndpoints.gameRoomCreate, data: data),
      ),
      ..._legacyAutoMatchPayloads(game).map(
        (data) => (path: ApiEndpoints.gamePlay, data: data),
      ),
    ];

    ApiException? lastError;
    for (final attempt in attempts) {
      try {
        final res = await _dio.safePost<dynamic>(
          attempt.path,
          data: attempt.data,
        );
        final room = _roomFromBody(res.data);
        if (room != null) return room;
      } on ApiException catch (e) {
        lastError = e;
        if (e.statusCode == 404 || e.statusCode == 405) continue;
        rethrow;
      }
    }
    throw lastError ?? ApiException('Eşleşme bulunamadı ($gameType)');
  }

  Future<GameRoomItem?> joinRoom(String roomId) async {
    final joinPaths = [
      ApiEndpoints.gameRoomJoin(roomId),
      ApiEndpoints.gameRoomJoinLegacy(roomId),
    ];

    ApiException? lastError;
    for (final path in joinPaths) {
      try {
        final res = await _dio.safePost<dynamic>(path);
        final room = _roomFromBody(res.data);
        if (room != null) return room;
      } on ApiException catch (e) {
        lastError = e;
        if (e.statusCode == 404 || e.statusCode == 405) continue;
        rethrow;
      }
    }
    throw lastError ?? ApiException('Odaya katılınamadı');
  }

  Future<GameRoomStateSnapshot> fetchRoomState(String roomId) async {
    final attempts = <Future<Response<dynamic>> Function()>[
      () => _dio.safeGet<dynamic>(ApiEndpoints.gameRoom(roomId)),
      () => _dio.safePost<dynamic>(
        ApiEndpoints.gameRoom(roomId),
        data: const {'action': 'state'},
      ),
      () => _dio.safePost<dynamic>(
        ApiEndpoints.gamePlay,
        data: {'action': 'state', 'roomId': roomId},
      ),
    ];

    for (final attempt in attempts) {
      try {
        final res = await attempt();
        return GameRoomStateSnapshot.fromJson(roomId, _map(res.data));
      } on ApiException catch (e) {
        if (e.statusCode == 404 || e.statusCode == 405) continue;
        rethrow;
      }
    }
    throw ApiException('Oda durumu alınamadı ($roomId)');
  }

  Future<GameRoomStateSnapshot> sendMove({
    required String roomId,
    required Map<String, dynamic> move,
    String? gameType,
  }) async {
    final slug = _normalizeGameType(gameType ?? move['gameType']?.toString());
    final payloads = _movePayloads(move);
    final paths = <String Function()>[
      () => ApiEndpoints.gameRoom(roomId),
      () => ApiEndpoints.gamePlay,
    ];

    ApiException? lastError;
    for (final pathFn in paths) {
      for (final data in payloads) {
        try {
          final body = pathFn() == ApiEndpoints.gamePlay
              ? {
                  ...data,
                  'roomId': roomId,
                  if (slug != null && slug.isNotEmpty) ...{
                    'gameType': slug,
                    'gameSlug': slug,
                    'slug': slug,
                  },
                }
              : data;
          final res = await _dio.safePost<dynamic>(pathFn(), data: body);
          return GameRoomStateSnapshot.fromJson(roomId, _map(res.data));
        } on ApiException catch (e) {
          lastError = e;
          if (e.statusCode == 404 || e.statusCode == 405) continue;
          rethrow;
        }
      }
    }
    throw lastError ?? const ApiException('Hamle gönderilemedi');
  }

  Future<void> sendChat({required String roomId, required String text}) async {
    final message = text.trim();
    if (message.isEmpty) return;

    await _dio.safePost<dynamic>(
      ApiEndpoints.gameRoomChat(roomId),
      data: {'message': message, 'text': message, 'content': message},
    );
  }

  Future<List<GameScoreItem>> fetchLeaderboard({String period = 'weekly'}) async {
    final res = await _dio.safePost<dynamic>(
      ApiEndpoints.gameLeaderboard,
      data: {'period': period, 'range': period},
    );
    return _scores(res.data);
  }

  Future<void> saveGameResult({
    required String gameId,
    required int score,
    Map<String, dynamic>? metadata,
  }) async {
    await _dio.safePost<dynamic>(
      ApiEndpoints.gameMiniScores,
      data: {
        'gameId': gameId,
        'score': score,
        'type': 'game-center',
        ...?metadata,
      },
    );
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

  /// Kılavuz GameRepository `dailySpin` — `POST /api/games/daily-spin`.
  Future<DailySpinResult> dailySpin() async {
    return _postDailyClaim(ApiEndpoints.gamesDailySpin);
  }

  /// GameRepository `dailyReward` — önce `/api/games/daily-reward`,
  /// sonra kılavuz `POST /api/daily-login`, son olarak `POST /api/daily-rewards`.
  Future<DailySpinResult> dailyReward() async {
    ApiException? last;
    for (final path in [
      ApiEndpoints.gamesDailyReward,
      ApiEndpoints.dailyLogin,
      ApiEndpoints.homeDailyRewards,
    ]) {
      try {
        return await _postDailyClaim(path);
      } on ApiException catch (e) {
        last = e;
        if (e.statusCode == 404 || e.statusCode == 405) continue;
        rethrow;
      }
    }
    throw last ?? ApiException('Günlük ödül alınamadı');
  }

  Future<DailySpinResult> _postDailyClaim(String path) async {
    try {
      final res = await _dio.safePost<dynamic>(path);
      return DailySpinResult.fromJson(_map(res.data));
    } on ApiException catch (e) {
      final msg = e.message.toLowerCase();
      if (e.statusCode == 400 ||
          e.statusCode == 409 ||
          msg.contains('already') ||
          msg.contains('bugün') ||
          msg.contains('bugun') ||
          msg.contains('zaten')) {
        return DailySpinResult(alreadySpun: true, message: e.message);
      }
      rethrow;
    }
  }

  Future<List<GameScoreItem>> fetchTournaments() async {
    final res = await _dio.safeGet<dynamic>(ApiEndpoints.tournaments);
    return _scores(res.data);
  }

  Future<void> joinTournament(String tournamentId) async {
    await _dio.safePost<dynamic>(
      ApiEndpoints.tournamentsJoin,
      data: {'tournamentId': tournamentId, 'id': tournamentId},
    );
  }

  String _gameType(GameCatalogItem game) {
    return _normalizeGameType(game.id) ?? game.id.trim().toLowerCase();
  }

  String? _normalizeGameType(String? value) {
    final id = value?.toLowerCase().trim() ?? '';
    if (id.isEmpty) return null;
    if (id.contains('okey101') || id == 'yuzbirokey' || id == 'okey-101') {
      return 'okey101';
    }
    if (id == 'okey') return 'okey';
    if (id == 'tavla') return 'tavla';
    if (id == 'pisti') return 'pisti';
    if (id == 'tombala') return 'tombala';
    if (id.contains('xox') || id.contains('tic')) return 'xox';
    return id;
  }

  List<Map<String, dynamic>> _legacyCreatePayloads(GameCatalogItem game) {
    final slug = _gameType(game);
    return [
      {
        'gameId': slug,
        'type': slug,
        'slug': slug,
        'gameSlug': slug,
        'title': game.title,
        if (game.jetonCost > 0) 'jetonCost': game.jetonCost,
      },
    ];
  }

  List<Map<String, dynamic>> _legacyAutoMatchPayloads(GameCatalogItem game) {
    final slug = _gameType(game);
    return [
      {'gameId': slug, 'type': slug, 'slug': slug, 'gameSlug': slug},
    ];
  }

  List<Map<String, dynamic>> _movePayloads(Map<String, dynamic> move) {
    final type = move['type']?.toString() ?? '';
    return [
      {'action': 'move', 'move': move},
      {'action': type, ...move},
      move,
    ];
  }

  List<GameRoomItem> _parseRooms(dynamic body) {
    return _items(
      body,
      const ['rooms', 'items', 'data', 'results'],
    ).map(GameRoomItem.fromJson).where((room) => room.id.isNotEmpty).toList();
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
}
