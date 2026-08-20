/// `GET /api/chat/rooms/{roomId}/speak-request` yanıtı.
class SpeakRequestStatus {
  const SpeakRequestStatus({
    this.pending = false,
    this.requestId,
    this.blocked = false,
    this.blockReason,
    this.blockExpiresAt,
  });

  final bool pending;
  final String? requestId;
  final bool blocked;
  final String? blockReason;
  final DateTime? blockExpiresAt;

  static const empty = SpeakRequestStatus();

  factory SpeakRequestStatus.fromJson(dynamic raw) {
    if (raw is! Map) return SpeakRequestStatus.empty;
    final request = raw['request'];
    var pending = false;
    String? requestId;
    if (request is Map) {
      final status = request['status']?.toString().toLowerCase();
      pending = status == 'pending';
      requestId = request['id']?.toString();
    }
    final blocked = raw['blocked'] == true;
    final reason = raw['blockReason']?.toString() ?? raw['reason']?.toString();
    DateTime? expires;
    final expRaw = raw['blockExpiresAt'] ?? raw['expiresAt'];
    if (expRaw != null) {
      expires = DateTime.tryParse(expRaw.toString());
    }
    return SpeakRequestStatus(
      pending: pending,
      requestId: requestId,
      blocked: blocked,
      blockReason: reason,
      blockExpiresAt: expires,
    );
  }
}

/// Konuşma isteği SSE / popup kuyruğu öğesi.
class VoiceSpeakRequestIncoming {
  const VoiceSpeakRequestIncoming({
    required this.roomKey,
    required this.userId,
    required this.userName,
    required this.requestId,
    this.avatar,
    this.message,
  });

  final String roomKey;
  final String userId;
  final String userName;
  final String requestId;
  final String? avatar;
  final String? message;

  String get dedupeKey => '$roomKey:$requestId';

  factory VoiceSpeakRequestIncoming.fromPayload(
    String roomKey,
    Map<String, dynamic> payload,
  ) {
    final requestId = (payload['requestId'] ?? payload['id'] ?? '').toString();
    final userId = (payload['userId'] ?? '').toString();
    final userName = (payload['userName'] ??
            payload['name'] ??
            payload['displayName'] ??
            'Kullanıcı')
        .toString();
    return VoiceSpeakRequestIncoming(
      roomKey: roomKey,
      userId: userId,
      userName: userName,
      requestId: requestId,
      avatar: payload['avatar']?.toString(),
      message: payload['message']?.toString(),
    );
  }
}
