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

  bool matchesCandidate(String candidate) {
    final c = candidate.trim();
    if (c.isEmpty) return false;
    if (c == active) return true;
    if (c.endsWith(active) || active.endsWith(c)) return true;
    return false;
  }

  bool matchesAlternate(String alt) {
    final a = alt.trim();
    if (a.isEmpty) return false;
    if (matchesCandidate(a)) return true;
    if (raw == a || raw.endsWith(a) || a.endsWith(raw)) return true;
    return false;
  }

  if (matchesCandidate(raw)) return true;
  final alt = alternateRoomId?.trim();
  if (alt != null && alt.isNotEmpty && matchesAlternate(alt)) return true;
  if (extraAlternateRoomIds != null) {
    for (final key in extraAlternateRoomIds) {
      if (matchesAlternate(key)) return true;
    }
  }
  return false;
}
