/// SSE/REST PK olayları — `eventId` tekrarlarını atla.
class LivePkEventDedup {
  LivePkEventDedup({this.maxEntries = 256});

  final int maxEntries;
  final _seen = <String>{};
  final _order = <String>[];

  bool shouldProcess(Map<String, dynamic> battle) {
    final id = _extractEventId(battle);
    if (id.isEmpty) return true;
    if (_seen.contains(id)) return false;
    _remember(id);
    return true;
  }

  void clear() {
    _seen.clear();
    _order.clear();
  }

  static String _extractEventId(Map<String, dynamic> battle) {
    for (final key in [
      'eventId',
      'sseEventId',
      'messageId',
      'transactionId',
      'giftTransactionId',
    ]) {
      final v = battle[key]?.toString().trim() ?? '';
      if (v.isNotEmpty) return v;
    }
    return '';
  }

  void _remember(String id) {
    _seen.add(id);
    _order.add(id);
    while (_order.length > maxEntries) {
      final old = _order.removeAt(0);
      _seen.remove(old);
    }
  }
}
