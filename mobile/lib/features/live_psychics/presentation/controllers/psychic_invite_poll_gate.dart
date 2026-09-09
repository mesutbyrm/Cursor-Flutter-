/// İlk API poll'da bekleyen davetleri kuyruğa alır ama dialog göstermez.
/// Oturum içinde yalnızca yeni gelen pending davetler sunulur.
class PsychicInvitePollGate {
  final _knownPending = <String>{};
  var _initialPollDone = false;

  /// İlk poll: tüm pending sessionId'leri kaydet, sunma.
  /// Sonraki poll: yalnızca yeni sessionId'leri döndür.
  List<String> takeNewPendingSessionIds(Iterable<String> pendingIds) {
    final ids = pendingIds
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
    if (!_initialPollDone) {
      _initialPollDone = true;
      _knownPending.addAll(ids);
      return const [];
    }
    final fresh = <String>[];
    for (final id in ids) {
      if (_knownPending.add(id)) fresh.add(id);
    }
    return fresh;
  }

  void noteSeen(String sessionId) {
    final id = sessionId.trim();
    if (id.isNotEmpty) _knownPending.add(id);
  }
}
