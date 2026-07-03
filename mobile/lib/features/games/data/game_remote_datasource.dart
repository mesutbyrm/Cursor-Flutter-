import 'package:dio/dio.dart';

import '../../../core/network/api_endpoints.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/network/dio_provider.dart';
import '../../../core/util/json_util.dart';
import '../domain/game_models.dart';
import 'okey101_local_session.dart';

typedef UserIdResolver = String? Function();
typedef DisplayNameResolver = String Function();

class GameRemoteDataSource {
  GameRemoteDataSource(
    this._dio, {
    Dio? gamesDio,
    UserIdResolver? resolveUserId,
    DisplayNameResolver? resolveDisplayName,
  })  : _gamesDio = gamesDio ?? _dio,
        _resolveUserId = resolveUserId ?? (() => null),
        _resolveDisplayName = resolveDisplayName ?? (() => 'Oyuncu');

  final Dio _dio;
  final Dio _gamesDio;
  final UserIdResolver _resolveUserId;
  final DisplayNameResolver _resolveDisplayName;
  final _local = Okey101LocalSession.instance;

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
    final remote = await _fetchRoomsRemote();
    final local = _local.openRooms();
    final byId = {for (final r in remote) r.id: r};
    for (final room in local) {
      byId.putIfAbsent(room.id, () => room);
    }
    return byId.values.toList();
  }

  Future<List<GameRoomItem>> _fetchRoomsRemote() async {
    try {
      final res = await _gamesDio.safeGet<dynamic>(ApiEndpoints.gameRooms);
      final rooms = _parseRooms(res.data);
      if (rooms.isNotEmpty) return rooms;
    } on ApiException catch (e) {
      if (e.statusCode != 404 && e.statusCode != 405) rethrow;
    } catch (_) {}

    // Eski üretim yedeği
    try {
      final res = await _gamesDio.safeGet<dynamic>(
        ApiEndpoints.gameRoomCreate,
        query: {'gameType': 'okey101', 'slug': 'okey101'},
      );
      return _parseRooms(res.data);
    } on ApiException catch (e) {
      if (e.statusCode != 404 && e.statusCode != 405) rethrow;
    } catch (_) {}

    return const [];
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

    for (final attempt in attempts) {
      try {
        final res = await _gamesDio.safePost<dynamic>(
          attempt.path,
          data: attempt.data,
        );
        final room = _roomFromBody(res.data);
        if (room != null) return room;
      } on ApiException catch (e) {
        if (e.statusCode == 404 || e.statusCode == 405) continue;
        rethrow;
      }
    }

    if (_isOkey101(game.id)) {
      return _local.createRoom(
        hostUserId: _userId(),
        hostName: _resolveDisplayName(),
        game: game,
      );
    }
    return null;
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

    for (final attempt in attempts) {
      try {
        final res = await _gamesDio.safePost<dynamic>(
          attempt.path,
          data: attempt.data,
        );
        final room = _roomFromBody(res.data);
        if (room != null) return room;
      } on ApiException catch (e) {
        if (e.statusCode == 404 || e.statusCode == 405) continue;
        rethrow;
      }
    }

    if (_isOkey101(game.id)) {
      return _local.autoMatch(
        userId: _userId(),
        displayName: _resolveDisplayName(),
        game: game,
      );
    }
    return null;
  }

  Future<GameRoomItem?> joinRoom(String roomId) async {
    if (_local.hasRoom(roomId)) {
      return _local.joinRoom(
        roomId: roomId,
        userId: _userId(),
        displayName: _resolveDisplayName(),
      );
    }

    final joinPaths = [
      ApiEndpoints.gameRoomJoin(roomId),
      ApiEndpoints.gameRoomJoinLegacy(roomId),
    ];

    for (final path in joinPaths) {
      try {
        final res = await _gamesDio.safePost<dynamic>(path);
        final room = _roomFromBody(res.data);
        if (room != null) return room;
      } on ApiException catch (e) {
        if (e.statusCode == 404 || e.statusCode == 405) continue;
        if (e.statusCode == 404 && _local.hasRoom(roomId)) {
          return _local.joinRoom(
            roomId: roomId,
            userId: _userId(),
            displayName: _resolveDisplayName(),
          );
        }
        rethrow;
      }
    }

    return null;
  }

  Future<GameRoomStateSnapshot> fetchRoomState(String roomId) async {
    if (_local.hasRoom(roomId)) {
      return _snapshotFromRaw(
        roomId,
        _local.roomState(roomId, _userId()),
      );
    }

    final attempts = <Future<Response<dynamic>> Function()>[
      () => _gamesDio.safeGet<dynamic>(ApiEndpoints.gameRoom(roomId)),
      () => _gamesDio.safePost<dynamic>(
        ApiEndpoints.gameRoom(roomId),
        data: const {'action': 'state'},
      ),
      () => _gamesDio.safePost<dynamic>(
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
      } catch (_) {}
    }

    if (_local.hasRoom(roomId)) {
      return _snapshotFromRaw(roomId, _local.roomState(roomId, _userId()));
    }
    return GameRoomStateSnapshot(roomId: roomId, status: 'unknown');
  }

  Future<GameRoomStateSnapshot> sendMove({
    required String roomId,
    required Map<String, dynamic> move,
  }) async {
    if (_local.hasRoom(roomId)) {
      return _snapshotFromRaw(
        roomId,
        _local.sendMove(roomId: roomId, userId: _userId(), move: move),
      );
    }

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
                  'gameType': 'okey101',
                  'gameSlug': 'okey101',
                  'slug': 'okey101',
                }
              : data;
          final res = await _gamesDio.safePost<dynamic>(pathFn(), data: body);
          return GameRoomStateSnapshot.fromJson(roomId, _map(res.data));
        } on ApiException catch (e) {
          lastError = e;
          if (e.statusCode == 404 || e.statusCode == 405) continue;
          rethrow;
        }
      }
    }

    if (_local.hasRoom(roomId)) {
      return _snapshotFromRaw(
        roomId,
        _local.sendMove(roomId: roomId, userId: _userId(), move: move),
      );
    }
    throw lastError ?? const ApiException('Hamle gönderilemedi');
  }

  Future<void> sendChat({required String roomId, required String text}) async {
    final message = text.trim();
    if (message.isEmpty) return;

    if (_local.hasRoom(roomId)) {
      _local.sendChat(roomId: roomId, userId: _userId(), text: message);
      return;
    }

    try {
      await _gamesDio.safePost<dynamic>(
        ApiEndpoints.gameRoomChat(roomId),
        data: {'message': message, 'text': message, 'content': message},
      );
    } on ApiException catch (e) {
      if (e.statusCode == 404 && _local.hasRoom(roomId)) {
        _local.sendChat(roomId: roomId, userId: _userId(), text: message);
        return;
      }
      rethrow;
    }
  }

  Future<List<GameScoreItem>> fetchLeaderboard({String period = 'weekly'}) async {
    try {
      final res = await _dio.safePost<dynamic>(
        ApiEndpoints.gameLeaderboard,
        data: {'period': period, 'range': period},
      );
      return _scores(res.data);
    } catch (_) {
      return const [];
    }
  }

  Future<void> saveGameResult({
    required String gameId,
    required int score,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      await _dio.safePost<dynamic>(
        ApiEndpoints.gameMiniScores,
        data: {
          'gameId': gameId,
          'score': score,
          'type': 'game-center',
          ...?metadata,
        },
      );
    } catch (_) {
      await saveMiniScore(gameId: gameId, score: score);
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

  String _userId() => _resolveUserId() ?? 'mobile-player';

  String _gameType(GameCatalogItem game) {
    if (_isOkey101(game.id)) return 'okey101';
    return game.id.trim().toLowerCase();
  }

  bool _isOkey101(String gameId) {
    final id = gameId.toLowerCase();
    return id.contains('okey101') || id == 'yuzbirokey' || id == 'okey-101';
  }

  List<Map<String, dynamic>> _legacyCreatePayloads(GameCatalogItem game) {
    final slugs = _isOkey101(game.id)
        ? const ['okey101', 'yuzbirokey', 'okey-101']
        : [game.id];
    final payloads = <Map<String, dynamic>>[];
    for (final slug in slugs) {
      payloads.addAll([
        {
          'gameId': slug,
          'type': slug,
          'slug': slug,
          'gameSlug': slug,
          'title': game.title,
          if (game.jetonCost > 0) 'jetonCost': game.jetonCost,
        },
        {
          'action': 'create',
          'gameId': slug,
          'slug': slug,
          'gameSlug': slug,
          'title': game.title,
          'maxPlayers': 4,
        },
      ]);
    }
    return payloads;
  }

  List<Map<String, dynamic>> _legacyAutoMatchPayloads(GameCatalogItem game) {
    final slugs = _isOkey101(game.id)
        ? const ['okey101', 'yuzbirokey', 'okey-101']
        : [game.id];
    final payloads = <Map<String, dynamic>>[];
    for (final slug in slugs) {
      payloads.addAll([
        {'gameId': slug, 'type': slug, 'slug': slug, 'gameSlug': slug},
        {
          'action': 'autoMatch',
          'gameId': slug,
          'slug': slug,
          'gameSlug': slug,
        },
        {
          'action': 'match',
          'gameSlug': slug,
          'slug': slug,
        },
      ]);
    }
    return payloads;
  }

  List<Map<String, dynamic>> _movePayloads(Map<String, dynamic> move) {
    final type = move['type']?.toString() ?? '';
    return [
      {'action': 'move', 'move': move},
      {'action': type, ...move},
      move,
      {'type': type, 'move': move, 'action': 'move'},
    ];
  }

  List<GameRoomItem> _parseRooms(dynamic body) {
    return _items(
      body,
      const ['rooms', 'items', 'data', 'results'],
    ).map(GameRoomItem.fromJson).where((room) => room.id.isNotEmpty).toList();
  }

  GameRoomStateSnapshot _snapshotFromRaw(
    String roomId,
    Map<String, dynamic> raw,
  ) {
    return GameRoomStateSnapshot.fromJson(roomId, raw);
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
