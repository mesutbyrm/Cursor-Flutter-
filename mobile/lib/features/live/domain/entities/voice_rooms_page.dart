import 'voice_room_entity.dart';

/// Sayfalanmış sesli oda listesi yanıtı.
class VoiceRoomsPage {
  const VoiceRoomsPage({
    required this.rooms,
    required this.page,
    required this.hasMore,
  });

  final List<VoiceRoomEntity> rooms;
  final int page;
  final bool hasMore;
}
