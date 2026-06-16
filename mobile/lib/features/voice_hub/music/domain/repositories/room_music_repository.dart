import '../../../domain/entities/music_queue_item.dart';
import '../entities/room_playback_sync.dart';

abstract class RoomMusicRepository {
  Future<List<YoutubeSearchHit>> searchSongs(String query, {int limit = 5});

  Future<({
    MusicQueueItem? item,
    List<MusicQueueItem> queue,
    int? queuePosition,
    String? streamUrl,
    bool playing,
    int? newBalance,
  })> enqueueSong({
    required String roomId,
    String? alternateRoomId,
    required String videoId,
    required String title,
    String? channelTitle,
    String? thumbUrl,
    String? duration,
    bool priority,
    bool skipPayment,
  });

  Future<String?> resolveStreamUrl({
    required String roomId,
    required String videoId,
  });

  Future<RoomPlaybackSync?> fetchPlaybackSync(String roomId);

  Future<void> controlPlayback({
    required String roomId,
    String? alternateRoomId,
    required String action,
  });
}
