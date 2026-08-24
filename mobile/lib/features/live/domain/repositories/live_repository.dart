import '../entities/live_stream_entity.dart';
import '../entities/voice_room_entity.dart';
import '../entities/voice_rooms_page.dart';

abstract class LiveRepository {
  Future<List<LiveStreamEntity>> fetchStreams({int page = 1, String? category});

  Future<List<VoiceRoomEntity>> fetchVoiceRooms({String? category});

  Future<VoiceRoomsPage> fetchVoiceRoomsPage({
    int page = 1,
    int limit = 30,
    String? category,
  });

  Future<VoiceRoomEntity?> fetchVoiceRoomById(String id);

  /// canlifal.com — ücretsiz / normal (2500) / VIP (5000) jeton ile sesli sohbet odası aç.
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
