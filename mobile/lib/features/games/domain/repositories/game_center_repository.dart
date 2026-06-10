import '../game_center_models.dart';
import '../game_models.dart';

/// Oyun merkezi veri sözleşmesi.
abstract interface class GameCenterRepository {
  Future<int> fetchJetonBalance();

  Future<List<LeaderboardEntry>> fetchLeaderboard(LeaderboardPeriod period);

  Future<List<GameRoomItem>> fetchLiveRooms();

  Future<void> saveGameResult(GameResultPayload result);

  Future<GameRoomItem?> createLiveRoom(String gameId);

  Future<GameRoomItem?> joinLiveRoom(String roomId);
}
