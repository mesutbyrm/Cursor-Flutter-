import '../entities/live_stream_entity.dart';
import '../entities/voice_room_entity.dart';

abstract class LiveRepository {
  Future<List<LiveStreamEntity>> fetchStreams({int page});

  Future<List<VoiceRoomEntity>> fetchVoiceRooms();
}
