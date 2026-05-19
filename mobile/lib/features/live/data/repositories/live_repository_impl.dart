import '../../domain/entities/live_stream_entity.dart';
import '../../domain/entities/voice_room_entity.dart';
import '../../domain/repositories/live_repository.dart';
import '../datasources/live_remote_datasource.dart';

class LiveRepositoryImpl implements LiveRepository {
  LiveRepositoryImpl(this._remote);

  final LiveRemoteDataSource _remote;

  @override
  Future<List<LiveStreamEntity>> fetchStreams({int page = 1}) =>
      _remote.fetch(page: page);

  @override
  Future<List<VoiceRoomEntity>> fetchVoiceRooms() => _remote.fetchVoiceRooms();

  @override
  Future<String> createVideoStream({
    required String title,
    String? description,
    String? category,
    List<String>? tags,
  }) =>
      _remote.createVideoStream(
        title: title,
        description: description,
        category: category,
        tags: tags,
      );

  @override
  Future<void> endVideoStream(String streamId) => _remote.endVideoStream(streamId);
}
