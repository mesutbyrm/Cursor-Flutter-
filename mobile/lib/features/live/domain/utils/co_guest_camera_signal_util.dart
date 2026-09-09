/// `co_guest_camera` sinyal ayrıştırma — poll ve SSE ortak.

String liveSignalType(Map<String, dynamic> sig) =>
    (sig['type'] ?? sig['event'] ?? '').toString().toLowerCase();

bool isCoGuestCameraSignal(Map<String, dynamic> sig) =>
    liveSignalType(sig) == 'co_guest_camera';

bool coGuestCameraTargetsUser(Map<String, dynamic> sig, String userId) {
  final receiver =
      (sig['receiverId'] ?? sig['targetUserId'] ?? '').toString().trim();
  if (receiver.isEmpty) return true;
  return receiver == userId;
}

Map<String, dynamic> coGuestCameraData(Map<String, dynamic> sig) {
  if (sig['data'] is Map) {
    return Map<String, dynamic>.from(sig['data'] as Map);
  }
  if (sig['payload'] is Map) {
    return Map<String, dynamic>.from(sig['payload'] as Map);
  }
  return <String, dynamic>{};
}

bool parseCoGuestCameraEnabled(Map<String, dynamic> sig) {
  final data = coGuestCameraData(sig);
  final enabled = data['enabled'] ?? sig['enabled'];
  return enabled == true ||
      enabled == 1 ||
      enabled == 'true' ||
      enabled == 'on';
}

/// Misafir cihazda kamera durumu; geçersiz sinyal için `null`.
bool? resolveCoGuestCameraForUser({
  required Map<String, dynamic> sig,
  required String selfUserId,
}) {
  if (!isCoGuestCameraSignal(sig)) return null;
  if (!coGuestCameraTargetsUser(sig, selfUserId)) return null;
  return parseCoGuestCameraEnabled(sig);
}
