/// Oda izolasyonu — gift / PK / müzik SSE olayları yalnızca aktif odaya uygulanır.
bool roomEventMatchesActiveRoom({
  required String? eventRoomId,
  required String? activeRoomId,
  Iterable<String>? alternateActiveKeys,
}) {
  final active = activeRoomId?.trim() ?? '';
  if (active.isEmpty) return true;

  final incoming = eventRoomId?.trim() ?? '';
  if (incoming.isEmpty) return true;
  if (roomKeysEquivalent(incoming, active)) return true;
  if (alternateActiveKeys != null) {
    for (final k in alternateActiveKeys) {
      if (roomKeysEquivalent(incoming, k)) return true;
    }
  }
  return false;
}

/// TRTC / SSE oda anahtarı önekleri (`VoiceTrtcEngine.trtcRoomIdFor`).
const _roomKeyPrefixes = ['voice_room_', 'room_', 'live-'];

String _stripRoomKeyPrefix(String key) {
  for (final p in _roomKeyPrefixes) {
    if (key.startsWith(p) && key.length > p.length) {
      return key.substring(p.length);
    }
  }
  return key;
}

/// İki oda anahtarı aynı odayı mı gösteriyor — TEK eşleştirme kuralı
/// (gift köprüsü + sesli oda SSE süzgeci, VOICE-006). Büyük/küçük harf
/// duyarsız; bilinen TRTC önekleri (`voice_room_`, `room_`, `live-`) yok
/// sayılır. Rastgele sonek eşleşmesi YOK (`"11"` ≠ `"1"`).
bool roomKeysEquivalent(String a, String b) {
  final x = a.trim().toLowerCase();
  final y = b.trim().toLowerCase();
  if (x.isEmpty || y.isEmpty) return false;
  if (x == y) return true;
  return _stripRoomKeyPrefix(x) == _stripRoomKeyPrefix(y);
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
