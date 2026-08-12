import '../../domain/entities/live_stream_entity.dart';
import '../../domain/entities/voice_room_entity.dart';
import '../../domain/entities/voice_rooms_page.dart';
import '../../domain/repositories/live_repository.dart';
import '../datasources/live_remote_datasource.dart';

class LiveRepositoryImpl implements LiveRepository {
  LiveRepositoryImpl(this._remote);

  final LiveRemoteDataSource _remote;

  @override
  Future<List<LiveStreamEntity>> fetchStreams({int page = 1, String? category}) =>
      _remote.fetch(page: page, category: category);

  @override
  Future<List<VoiceRoomEntity>> fetchVoiceRooms() => _remote.fetchVoiceRooms();

  @override
  Future<VoiceRoomsPage> fetchVoiceRoomsPage({int page = 1, int limit = 30}) =>
      _remote.fetchVoiceRoomsPage(page: page, limit: limit);

  @override
  Future<VoiceRoomEntity?> fetchVoiceRoomById(String id) =>
      _remote.fetchVoiceRoomById(id);

  @override
  Future<VoiceRoomEntity> createVoiceChatRoom({
    bool vip = false,
    String? roomType,
    String? roomName,
    String paymentType = 'jeton',
    String? description,
    String? icon,
    String? background,
    int seatCount = 8,
    int maxUsers = 15,
    String? category,
  }) =>
      _remote.createVoiceChatRoom(
        vip: vip,
        roomType: roomType,
        roomName: roomName,
        paymentType: paymentType,
        description: description,
        icon: icon,
        background: background,
        seatCount: seatCount,
        maxUsers: maxUsers,
        category: category,
      );

  @override
  Future<String> createVideoStream({
    required String title,
    String? description,
    String? category,
    List<String>? tags,
    String? thumbnailUrl,
    bool isPrivate = false,
    bool isImageMode = false,
    String? backgroundUrl,
  }) =>
      _remote.createVideoStream(
        title: title,
        description: description,
        category: category,
        tags: tags,
        thumbnailUrl: thumbnailUrl,
        isPrivate: isPrivate,
        isImageMode: isImageMode,
        backgroundUrl: backgroundUrl,
      );

  @override
  Future<void> endVideoStream(String streamId) => _remote.endVideoStream(streamId);

  @override
  Future<int> joinVideoStream(String streamId) =>
      _remote.joinVideoStream(streamId);

  @override
  Future<void> leaveVideoStream(String streamId) =>
      _remote.leaveVideoStream(streamId);
}
