import '../repositories/room_music_repository.dart';

class ControlPlaybackUseCase {
  ControlPlaybackUseCase(this._repository);

  final RoomMusicRepository _repository;

  Future<void> call({
    required String roomId,
    String? alternateRoomId,
    required String action,
  }) =>
      _repository.controlPlayback(
        roomId: roomId,
        alternateRoomId: alternateRoomId,
        action: action,
      );
}
