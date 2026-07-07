import '../../presentation/widgets/voice_rooms_ui/voice_rooms_mock_data.dart';
import '../../../live/domain/entities/voice_room_entity.dart';

enum VoiceRoomsNearbyTab { nearby, newest, friends }

class VoiceRoomsDiscoverBundle {
  const VoiceRoomsDiscoverBundle({
    required this.categories,
    required this.featured,
    required this.popular,
    required this.allRooms,
  });

  final List<VoiceCategoryItem> categories;
  final List<FeaturedRoomItem> featured;
  final List<PopularRoomItem> popular;
  final List<VoiceRoomEntity> allRooms;
}

abstract class VoiceRoomsDiscoverRepository {
  Future<VoiceRoomsDiscoverBundle> fetchDiscoverBundle({
    String? categoryId,
    bool forceRefresh = false,
  });

  Future<List<TrendingTopicItem>> fetchTrends({bool forceRefresh = false});

  Future<List<ActiveSpeakerItem>> fetchActiveSpeakers({
    bool forceRefresh = false,
  });

  List<NearbyRoomItem> mapNearbyPage({
    required List<VoiceRoomEntity> rooms,
    required VoiceRoomsNearbyTab tab,
    required int page,
    int pageSize = 6,
  });

  bool hasMoreNearby({
    required List<VoiceRoomEntity> rooms,
    required VoiceRoomsNearbyTab tab,
    required int loadedCount,
    int pageSize = 6,
  });
}
