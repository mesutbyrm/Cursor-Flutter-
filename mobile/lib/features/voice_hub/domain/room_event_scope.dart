/// SSE / gift / PK event'lerinde oda izolasyonu.
bool roomEventMatchesActiveRoom(
  Map<String, dynamic> payload,
  String activeRoomId, {
  String? alternateRoomId,
}) {
  final active = activeRoomId.trim();
  if (active.isEmpty) return false;

  final raw = payload['roomId']?.toString().trim() ??
      payload['room_id']?.toString().trim() ??
      payload['liveKey']?.toString().trim();
  if (raw == null || raw.isEmpty) {
    // Bağlantı zaten oda bazlı — roomId yoksa kabul et.
    return true;
  }

  bool matches(String candidate) {
    final c = candidate.trim();
    if (c.isEmpty) return false;
    if (c == active) return true;
    if (c.endsWith(active) || active.endsWith(c)) return true;
    final alt = alternateRoomId?.trim();
    if (alt != null && alt.isNotEmpty) {
      if (c == alt || c.endsWith(alt) || alt.endsWith(c)) return true;
    }
    return false;
  }

  return matches(raw);
}
