import '../../../live/domain/entities/voice_room_entity.dart';
import '../providers/voice_room_ranking_provider.dart';
import '../providers/voice_rooms_presence_provider.dart';

/// Keşfet listesi — proxy sıralama (SSE sayaç + PK/müzik skoru).
List<VoiceRoomEntity> orderDiscoverRoomsByProxyRanking(
  List<VoiceRoomEntity> rooms, {
  Map<String, int> livePresenceCounts = const {},
  int limit = 100,
}) {
  if (rooms.isEmpty) return const [];
  final ranked = buildVoiceRoomRanking(
    rooms,
    limit: limit,
    livePresenceCounts: livePresenceCounts,
  );
  if (ranked.isEmpty) {
    final fallback = [...rooms];
    fallback.sort((a, b) => b.displayOnline.compareTo(a.displayOnline));
    return fallback;
  }
  final orderedKeys = <String>{};
  final out = <VoiceRoomEntity>[];
  for (final entry in ranked) {
    final key = entry.room.apiRoomKey.isNotEmpty
        ? entry.room.apiRoomKey
        : entry.room.id;
    if (key.isEmpty || orderedKeys.contains(key)) continue;
    orderedKeys.add(key);
    out.add(entry.room);
  }
  for (final room in rooms) {
    final key =
        room.apiRoomKey.isNotEmpty ? room.apiRoomKey : room.id;
    if (key.isEmpty || orderedKeys.contains(key)) continue;
    out.add(room);
  }
  return out;
}

/// Saatlik sıra rozeti — yalnızca Top 10.
int? discoverHourlyRankForRoom(
  String roomKey,
  List<VoiceRoomRankEntry> hourly, {
  int maxBadgeRank = 10,
}) {
  final id = roomKey.trim();
  if (id.isEmpty || hourly.isEmpty) return null;
  for (final entry in hourly) {
    if (entry.rank > maxBadgeRank) break;
    final key = entry.room.apiRoomKey.isNotEmpty
        ? entry.room.apiRoomKey
        : entry.room.id;
    if (key == id || entry.room.id == id) return entry.rank;
  }
  return null;
}

/// Görünür keşfet odaları — SSE izleme için öncelikli küme (dedupe).
List<VoiceRoomEntity> pickDiscoverPresenceTrackRooms({
  required List<VoiceRoomEntity> spotlight,
  required List<VoiceRoomEntity> visible,
  int maxRooms = VoiceRoomsPresenceNotifier.maxTrackedRooms,
}) {
  final merged = <String, VoiceRoomEntity>{};
  for (final room in [...spotlight, ...visible]) {
    final key = room.apiRoomKey.isNotEmpty ? room.apiRoomKey : room.id;
    if (key.isEmpty) continue;
    merged[key] = room;
    if (merged.length >= maxRooms) break;
  }
  return merged.values.toList(growable: false);
}
