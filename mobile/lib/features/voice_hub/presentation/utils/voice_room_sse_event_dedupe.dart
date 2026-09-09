/// SSE / realtime event duplicate koruması.
class VoiceRoomSseEventDedupe {
  VoiceRoomSseEventDedupe({this.maxEntries = 400});

  final int maxEntries;
  final Set<String> _seen = {};

  bool shouldProcess(String? eventId) {
    final id = eventId?.trim() ?? '';
    if (id.isEmpty) return true;
    if (_seen.contains(id)) return false;
    _seen.add(id);
    if (_seen.length > maxEntries) {
      _seen.remove(_seen.first);
    }
    return true;
  }

  void clear() => _seen.clear();
}
