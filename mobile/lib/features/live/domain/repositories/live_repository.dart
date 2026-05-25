import '../entities/live_stream_entity.dart';
import '../entities/voice_room_entity.dart';

abstract class LiveRepository {
  Future<List<LiveStreamEntity>> fetchStreams({int page});

  Future<List<VoiceRoomEntity>> fetchVoiceRooms();

  Future<VoiceRoomEntity?> fetchVoiceRoomById(String id);

  /// canlifal.com — 100 jeton ile sesli sohbet odası aç.
  Future<VoiceRoomEntity> createVoiceChatRoom({bool vip = false});

  Future<String> createVideoStream({
    required String title,
    String? description,
    String? category,
    List<String>? tags,
  });

  Future<void> endVideoStream(String streamId);
}
