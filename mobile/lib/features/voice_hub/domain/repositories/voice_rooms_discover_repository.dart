import '../../presentation/widgets/voice_rooms_ui/voice_rooms_mock_data.dart';
import '../../../live/domain/entities/voice_room_entity.dart';
import '../../../live/domain/entities/voice_rooms_page.dart';

enum VoiceRoomsNearbyTab { nearby, newest, friends }

class VoiceRoomsDiscoverBundle {
  const VoiceRoomsDiscoverBundle({
    required this.categories,
    required this.featured,
    required this.popular,
    required this.allRooms,
    this.apiPage = 1,
    this.apiHasMore = false,
  });

  final List<VoiceCategoryItem> categories;
  final List<FeaturedRoomItem> featured;
  final List<PopularRoomItem> popular;
  final List<VoiceRoomEntity> allRooms;
  final int apiPage;
  final bool apiHasMore;
}

abstract class VoiceRoomsDiscoverRepository {
  Future<VoiceRoomsDiscoverBundle> fetchDiscoverBundle({
    String? categoryId,
    bool forceRefresh = false,
  });

  Future<VoiceRoomsPage> fetchRoomsPage({
    String? categoryId,
    required int page,
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
