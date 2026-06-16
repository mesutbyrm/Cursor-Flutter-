import '../../../domain/entities/music_queue_item.dart';
import '../../domain/entities/room_playback_sync.dart';
import '../../domain/repositories/room_music_repository.dart';
import '../datasources/room_music_remote_datasource.dart';

class RoomMusicRepositoryImpl implements RoomMusicRepository {
  RoomMusicRepositoryImpl(this._remote);

  final RoomMusicRemoteDataSource _remote;

  @override
  Future<List<YoutubeSearchHit>> searchSongs(String query, {int limit = 5}) =>
      _remote.searchSongs(query, limit: limit);

  @override
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
    bool priority = false,
    bool skipPayment = false,
  }) async {
    final key = roomId.trim();
    final alt = alternateRoomId?.trim();
    try {
      return await _remote.enqueueSong(
        roomId: key,
        videoId: videoId,
        title: title,
        channelTitle: channelTitle,
        thumbUrl: thumbUrl,
        duration: duration,
        priority: priority,
        skipPayment: skipPayment,
      );
    } catch (e) {
      if (alt != null && alt.isNotEmpty && alt != key) {
        return _remote.enqueueSong(
          roomId: alt,
          videoId: videoId,
          title: title,
          channelTitle: channelTitle,
          thumbUrl: thumbUrl,
          duration: duration,
          priority: priority,
          skipPayment: skipPayment,
        );
      }
      rethrow;
    }
  }

  @override
  Future<String?> resolveStreamUrl({
    required String roomId,
    required String videoId,
  }) =>
      _remote.resolveStreamUrl(roomId: roomId, videoId: videoId);

  @override
  Future<RoomPlaybackSync?> fetchPlaybackSync(String roomId) =>
      _remote.fetchDjSync(roomId);

  @override
  Future<void> controlPlayback({
    required String roomId,
    String? alternateRoomId,
    required String action,
  }) async {
    Future<void> run(String key) async {
      switch (action) {
        case 'pause':
          await _remote.pauseDj(key);
        case 'resume':
          await _remote.resumeDj(key);
        case 'stop':
          await _remote.stopQueue(key);
        case 'next':
          await _remote.skipQueue(key);
        default:
          break;
      }
    }

    try {
      await run(roomId);
    } catch (_) {
      final alt = alternateRoomId?.trim();
      if (alt != null && alt.isNotEmpty && alt != roomId) {
        await run(alt);
      } else {
        rethrow;
      }
    }
  }
}
