/// PK pane — battle `userId` ile TRTC `remoteUserIds` eşlemesi.
String? resolveLivePkTrtcRemoteUserId({
  required String? preferredUserId,
  required Iterable<String> remoteUserIds,
  required String? localTrtcUserId,
}) {
  final preferred = preferredUserId?.trim() ?? '';
  final local = localTrtcUserId?.trim() ?? '';
  final remotes = remoteUserIds
      .map((id) => id.trim())
      .where((id) => id.isNotEmpty && id != local)
      .toList();
  if (remotes.isEmpty) return null;

  if (preferred.isNotEmpty) {
    if (remotes.contains(preferred)) return preferred;
    for (final id in remotes) {
      if (id.toLowerCase() == preferred.toLowerCase()) return id;
    }
  }

  if (remotes.length == 1) return remotes.first;
  return null;
}
