import '../../../live/domain/entities/voice_room_entity.dart';

/// Oda route anahtarı (slug, kısmi cuid veya tam cuid) → SSE/TRTC için canonical Prisma id.
class VoiceRoomKeyResolver {
  VoiceRoomKeyResolver._();

  /// Minimum önek uzunluğu — yanlış eşleşmeyi azaltır.
  static const int minPrefixLength = 6;

  /// Bilinen oda listesinden route anahtarını tam cuid'ye çöz.
  static String? resolveFromKnownRooms(
    String routeKey,
    Iterable<VoiceRoomEntity> rooms,
  ) {
    final key = routeKey.trim();
    if (key.isEmpty) return null;
    final lower = key.toLowerCase();
    String norm(String s) =>
        s.trim().toLowerCase().replaceAll(RegExp(r'-+$'), '');

    for (final r in rooms) {
      final id = r.id.trim();
      final slug = r.slug.trim();
      if (id == key || slug == key) return id;
      if (id.toLowerCase() == lower || slug.toLowerCase() == lower) return id;
      if (norm(slug) == norm(key) || norm(id) == norm(key)) return id;
      if (key.length >= minPrefixLength &&
          id.length >= minPrefixLength &&
          id.toLowerCase().startsWith(lower)) {
        return id;
      }
    }
    return null;
  }

  static String canonicalApiKey({
    required String routeKey,
    required VoiceRoomEntity meta,
    Iterable<VoiceRoomEntity>? knownRooms,
  }) {
    final key = routeKey.trim();
    if (key.isEmpty) return key;

    final fromList =
        knownRooms == null ? null : resolveFromKnownRooms(key, knownRooms);
    if (fromList != null && fromList.length >= minPrefixLength) {
      return fromList;
    }

    final id = meta.id.trim();
    final slug = meta.slug.trim();
    if (id.isNotEmpty && slug.isNotEmpty && id != slug) return id;
    if (id.length >= 18) return id;
    if (key.length >= minPrefixLength &&
        id.length >= minPrefixLength &&
        id.toLowerCase().startsWith(key.toLowerCase())) {
      return id;
    }
    return key;
  }
}
