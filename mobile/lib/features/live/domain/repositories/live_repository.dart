import '../entities/live_stream_entity.dart';
import '../entities/voice_room_entity.dart';

abstract class LiveRepository {
  Future<List<LiveStreamEntity>> fetchStreams({int page});

  Future<List<VoiceRoomEntity>> fetchVoiceRooms();

  Future<VoiceRoomEntity?> fetchVoiceRoomById(String id);

  /// canlifal.com — normal 100 / VIP 5000 jeton ile sesli sohbet odası aç.
  Future<VoiceRoomEntity> createVoiceChatRoom({
    bool vip = false,
    String? roomName,
  });

  Future<String> createVideoStream({
    required String title,
    String? description,
    String? category,
    List<String>? tags,
    String? thumbnailUrl,
    bool isPrivate = false,
    bool isImageMode = false,
    String? backgroundUrl,
  });

  Future<void> endVideoStream(String streamId);

  Future<int> joinVideoStream(String streamId);

  Future<void> leaveVideoStream(String streamId);
}
