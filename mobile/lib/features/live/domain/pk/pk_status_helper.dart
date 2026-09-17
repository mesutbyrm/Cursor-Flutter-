/// PK davet durumu — backend `pending` ve `invited` eşdeğer.
bool isPkInvitePendingStatus(String? status) {
  final s = normalizePkStatus(status);
  return s == 'pending' || s == 'invited' || s == 'created' || s == 'waiting';
}

/// Sunucu / eski istemci farklı yazımlar.
String normalizePkStatus(String? status) =>
    (status ?? '').toLowerCase().trim();

/// Split video ve aktif PK UI — yalnızca gerçekten devam eden maç.
bool isLivePkActiveStatus(String? status) {
  final s = normalizePkStatus(status);
  return s == 'active' ||
      s == 'started' ||
      s == 'in_progress' ||
      s == 'running';
}

/// Kabul sonrası hazırlık / 3-2-1 — backend `starting` ve eşdeğerleri.
bool isLivePkStartingStatus(String? status) {
  final s = normalizePkStatus(status);
  return s == 'starting' || s == 'countdown' || s == 'preparing';
}

/// Aktif PK için iki yayın kimliği gerekli (erken split TRTC çökmesini önler).
bool isLivePkSplitReady(Map<String, dynamic>? battle, String? status) {
  if (battle == null || !isLivePkActiveStatus(status)) return false;
  final host = (battle['liveStreamId'] ??
          battle['hostStreamId'] ??
          battle['streamId'])
      ?.toString()
      .trim();
  final opponent = (battle['opponentLiveStreamId'] ??
          battle['opponentStreamId'] ??
          battle['targetStreamId'])
      ?.toString()
      .trim();
  return host != null &&
      host.isNotEmpty &&
      opponent != null &&
      opponent.isNotEmpty;
}
