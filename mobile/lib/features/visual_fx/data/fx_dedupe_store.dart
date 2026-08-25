/// Kısa süreli event deduplication — reconnect / çift SSE için.
class FxDedupeStore {
  FxDedupeStore({this.maxEntries = 512});

  final int maxEntries;
  final _seen = <String, int>{};

  /// `true` = ilk kez görüldü, işlenebilir.
  bool markIfNew(String eventId, {int? nowMs}) {
    final id = eventId.trim();
    if (id.isEmpty) return false;
    final now = nowMs ?? DateTime.now().millisecondsSinceEpoch;
    final prev = _seen[id];
    if (prev != null && now - prev < 120_000) return false;
    _seen[id] = now;
    _trim();
    return true;
  }

  void clear() => _seen.clear();

  void _trim() {
    if (_seen.length <= maxEntries) return;
    final sorted = _seen.entries.toList()
      ..sort((a, b) => a.value.compareTo(b.value));
    final removeCount = _seen.length - maxEntries;
    for (var i = 0; i < removeCount; i++) {
      _seen.remove(sorted[i].key);
    }
  }
}
