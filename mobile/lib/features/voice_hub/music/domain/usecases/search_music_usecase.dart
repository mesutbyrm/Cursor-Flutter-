import '../../../domain/entities/music_queue_item.dart';
import '../repositories/room_music_repository.dart';

class SearchMusicUseCase {
  SearchMusicUseCase(this._repository);

  final RoomMusicRepository _repository;

  Future<List<YoutubeSearchHit>> call(String query, {int limit = 10}) =>
      _repository.searchSongs(query, limit: limit);
}
