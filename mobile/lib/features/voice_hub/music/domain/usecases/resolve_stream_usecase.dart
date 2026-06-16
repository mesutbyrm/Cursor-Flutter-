import '../repositories/room_music_repository.dart';

class ResolveStreamUseCase {
  ResolveStreamUseCase(this._repository);

  final RoomMusicRepository _repository;

  Future<String?> call({
    required String roomId,
    required String videoId,
  }) =>
      _repository.resolveStreamUrl(roomId: roomId, videoId: videoId);
}
