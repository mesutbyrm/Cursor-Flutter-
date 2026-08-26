import '../../domain/game_center_models.dart';
import '../../domain/game_models.dart';
import '../../domain/repositories/game_center_repository.dart';
import '../game_remote_datasource.dart';
import '../../../profile/data/datasources/profile_remote_datasource.dart';

class GameCenterRepositoryImpl implements GameCenterRepository {
  GameCenterRepositoryImpl({
    required GameRemoteDataSource games,
    required WalletRemoteDataSource wallet,
  }) : _games = games,
       _wallet = wallet;

  final GameRemoteDataSource _games;
  final WalletRemoteDataSource _wallet;

  @override
  Future<int> fetchJetonBalance() async {
    try {
      final balances = await _wallet.balances();
      return balances.jeton;
    } catch (_) {
      return 0;
    }
  }

  @override
  Future<List<LeaderboardEntry>> fetchLeaderboard(
    LeaderboardPeriod period,
  ) async {
    final scores = await _games.fetchLeaderboard(period: period.apiValue);
    if (scores.isEmpty) return const [];
    return scores
        .asMap()
        .entries
        .map(
          (e) => LeaderboardEntry(
            id: e.value.id.isNotEmpty ? e.value.id : 'p${e.key}',
            name: e.value.title,
            score: e.value.score,
            rank: e.value.rank ?? e.key + 1,
          ),
        )
        .toList();
  }

  @override
  Future<List<GameRoomItem>> fetchLiveRooms() async {
    return _games.fetchRooms();
  }

  @override
  Future<void> saveGameResult(GameResultPayload result) async {
    await _games.saveGameResult(
      gameId: result.gameId,
      score: result.score,
      metadata: result.toJson(),
    );
  }

  @override
  Future<GameRoomItem?> createLiveRoom(String gameId) async {
    final catalog = await _games.fetchCatalog();
    final game = catalog.firstWhere(
      (g) => g.id == gameId,
      orElse: () => GameCatalogItem(
        id: gameId,
        title: gameId,
        kind: GameKind.multiplayer,
      ),
    );
    return _games.createRoom(game);
  }

  @override
  Future<GameRoomItem?> joinLiveRoom(String roomId) async {
    return _games.joinRoom(roomId);
  }

  @override
  Future<GameRoomItem?> autoMatchLiveRoom(String gameId) async {
    final catalog = await _games.fetchCatalog();
    final items = catalog.isNotEmpty ? catalog : GameCatalogFallback.all;
    final game = items.firstWhere(
      (g) => g.id == gameId,
      orElse: () => GameCatalogItem(
        id: gameId,
        title: gameId,
        kind: GameKind.multiplayer,
      ),
    );
    return _games.autoMatch(game);
  }

  @override
  Future<DailySpinResult> dailySpin() => _games.dailySpin();

  @override
  Future<DailySpinResult> dailyReward() => _games.dailyReward();
}
