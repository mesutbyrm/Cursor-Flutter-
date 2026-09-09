/// Keşfet / oda SSE — sıralama değişimi olay adları (ROOM_RANK_CHANGED hazırlığı).
bool isVoiceRoomRankChangedSseEvent(String? raw) {
  final ev = raw?.toLowerCase().trim() ?? '';
  if (ev.isEmpty) return false;
  return ev == 'room_rank_changed' ||
      ev == 'room_rank' ||
      ev == 'roomrankchanged' ||
      ev == 'ranking_updated' ||
      ev == 'room_ranking_updated';
}
