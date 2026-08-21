/// Oda izolasyonu — gift / PK / müzik SSE olayları yalnızca aktif odaya uygulanır.
bool roomEventMatchesActiveRoom({
  required String? eventRoomId,
  required String? activeRoomId,
  Iterable<String>? alternateActiveKeys,
}) {
  final active = activeRoomId?.trim() ?? '';
  if (active.isEmpty) return true;

  final keys = <String>{active.toLowerCase()};
  if (alternateActiveKeys != null) {
    for (final k in alternateActiveKeys) {
      final t = k.trim();
      if (t.isNotEmpty) keys.add(t.toLowerCase());
    }
  }

  final incoming = eventRoomId?.trim().toLowerCase() ?? '';
  if (incoming.isEmpty) return true;
  return keys.contains(incoming);
}

/// Aktif oda anahtarı ile oturum anahtarı eşleşiyor mu (slug / apiRoomKey / id).
bool sessionKeyMatchesActiveRoom({
  required String sessionKey,
  required String? activeRoomKey,
  Iterable<String>? roomAliases,
}) {
  return roomEventMatchesActiveRoom(
    eventRoomId: sessionKey,
    activeRoomId: activeRoomKey,
    alternateActiveKeys: roomAliases,
  );
}
