import '../../../core/room/room_event_scope.dart' show roomKeysEquivalent;

/// SSE / gift / PK event'lerinde oda izolasyonu.
bool roomEventMatchesActiveRoom(
  Map<String, dynamic> payload,
  String activeRoomId, {
  String? alternateRoomId,
  Iterable<String>? extraAlternateRoomIds,
}) {
  final active = activeRoomId.trim();
  if (active.isEmpty) return false;

  final raw = payload['roomId']?.toString().trim() ??
      payload['room_id']?.toString().trim() ??
      payload['liveKey']?.toString().trim() ??
      payload['voiceRoomId']?.toString().trim() ??
      payload['opponentRoomId']?.toString().trim();
  if (raw == null || raw.isEmpty) {
    // Bağlantı zaten oda bazlı — roomId yoksa kabul et.
    return true;
  }

  // Takma ad, ETKİN odanın başka bir kimliğidir: olayın oda kimliği bu takma
  // adla eşleşmeli. (Önceden `takma ad == etkin oda` ise HER olay kabul
  // ediliyordu → önceki odanın bayat olayları yeni odada işleniyordu.)
  // Eşleştirme kuralı gift köprüsüyle ortak: [roomKeysEquivalent].
  bool matchesAlternate(String alt) => roomKeysEquivalent(raw, alt);

  if (roomKeysEquivalent(raw, active)) return true;
  final alt = alternateRoomId?.trim();
  if (alt != null && alt.isNotEmpty && matchesAlternate(alt)) return true;
  if (extraAlternateRoomIds != null) {
    for (final key in extraAlternateRoomIds) {
      if (matchesAlternate(key)) return true;
    }
  }
  return false;
}
