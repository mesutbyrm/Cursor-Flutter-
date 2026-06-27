import '../../../domain/entities/music_queue_item.dart';
import '../repositories/room_music_repository.dart';

class EnqueueSongUseCase {
  EnqueueSongUseCase(this._repository);

  final RoomMusicRepository _repository;

  Future<({
    MusicQueueItem? item,
    List<MusicQueueItem> queue,
    int? queuePosition,
    String? streamUrl,
    bool playing,
    int? newBalance,
  })> call({
    required String roomId,
    String? alternateRoomId,
    required String videoId,
    required String title,
    String? channelTitle,
    String? thumbUrl,
    String? duration,
    bool priority = false,
    bool skipPayment = false,
    bool withVideo = false,
  }) =>
      _repository.enqueueSong(
        roomId: roomId,
        alternateRoomId: alternateRoomId,
        videoId: videoId,
        title: title,
        channelTitle: channelTitle,
        thumbUrl: thumbUrl,
        duration: duration,
        priority: priority,
        skipPayment: skipPayment,
        withVideo: withVideo,
      );
}
