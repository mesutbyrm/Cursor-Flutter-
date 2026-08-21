/// Oyun hamle/event tekrarını önlemek için yardımcılar.
abstract final class GameMoveDedupe {
  static String? extractEventId(Map<String, dynamic> raw) {
    for (final key in const [
      'eventId',
      'moveId',
      'lastMoveId',
      'lastEventId',
      'sequence',
      'seq',
      'version',
    ]) {
      final value = raw[key];
      if (value == null) continue;
      final text = value.toString().trim();
      if (text.isNotEmpty) return '$key:$text';
    }

    final lastMove = raw['lastMove'];
    if (lastMove is Map) {
      final nested = extractEventId(Map<String, dynamic>.from(lastMove));
      if (nested != null) return nested;
    }
    return null;
  }

  static bool shouldApplySnapshot({
    required Map<String, dynamic> raw,
    required Set<String> seenEventIds,
  }) {
    final eventId = extractEventId(raw);
    if (eventId == null) return true;
    if (seenEventIds.contains(eventId)) return false;
    seenEventIds.add(eventId);
    return true;
  }
}
