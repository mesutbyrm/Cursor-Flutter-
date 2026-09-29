import '../../domain/entities/chat_room_presence.dart';

/// Sunucu presence snapshot'ında kısa süre kalan hayalet üyeleri filtreler.
class VoicePresenceTombstone {
  VoicePresenceTombstone({Duration ttl = const Duration(minutes: 5)}) : _ttl = ttl;

  final Duration _ttl;
  final Map<String, DateTime> _departedUntil = {};

  void mark(String userId, {DateTime? now}) {
    final id = userId.trim();
    if (id.isEmpty) return;
    _departedUntil[id] = (now ?? DateTime.now()).add(_ttl);
  }

  void clear() => _departedUntil.clear();

  List<ChatRoomPresence> filter(
    List<ChatRoomPresence> incoming, {
    DateTime? now,
  }) {
    if (_departedUntil.isEmpty) return incoming;
    final clock = now ?? DateTime.now();
    _departedUntil.removeWhere((_, until) => !until.isAfter(clock));
    if (_departedUntil.isEmpty) return incoming;
    return incoming
        .where((p) {
          final until = _departedUntil[p.id];
          return until == null || !until.isAfter(clock);
        })
        .toList(growable: false);
  }
}
