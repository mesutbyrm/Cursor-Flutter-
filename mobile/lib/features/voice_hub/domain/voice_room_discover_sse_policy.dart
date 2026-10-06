import '../../../live/domain/entities/voice_room_entity.dart';

/// Keşif listesi SSE — aktif oda [VoiceRoomLiveController] tarafından dinlenir;
/// çift abone ve sayaç yarışını önlemek için keşif bu odayı izlemez.
abstract final class VoiceRoomDiscoverSsePolicy {
  static bool shouldSkipRoom({
    required String roomKey,
    required String roomEntityId,
    required String? activeLiveKey,
    Set<String> activeAliases = const {},
  }) {
    final active = activeLiveKey?.trim() ?? '';
    if (active.isEmpty) return false;
    if (roomKey == active || roomEntityId == active) return true;
    if (activeAliases.contains(roomKey) || activeAliases.contains(roomEntityId)) {
      return true;
    }
    return false;
  }

  static List<String> roomKeysToTrack({
    required List<VoiceRoomEntity> rooms,
    required int maxRooms,
    String? activeLiveKey,
    Set<String> activeAliases = const {},
  }) {
    final keys = <String>[];
    for (final room in rooms.take(maxRooms)) {
      final key = room.apiRoomKey.isNotEmpty ? room.apiRoomKey : room.id;
      if (key.isEmpty) continue;
      if (shouldSkipRoom(
        roomKey: key,
        roomEntityId: room.id,
        activeLiveKey: activeLiveKey,
        activeAliases: activeAliases,
      )) {
        continue;
      }
      keys.add(key);
    }
    return keys;
  }
}
