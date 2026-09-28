class CoBroadcast {
  final String id;
  final String hostId;
  final String? guestId;
  final String title;
  final String description;
  final DateTime startTime;
  final String status;
  final int viewerCount;
  final bool audioMixed;
  final bool videoEnabled;
  final List<String> permissions;

  CoBroadcast({
    required this.id,
    required this.hostId,
    this.guestId,
    required this.title,
    required this.description,
    required this.startTime,
    required this.status,
    required this.viewerCount,
    required this.audioMixed,
    required this.videoEnabled,
    required this.permissions,
  });

  bool get isLive => status == 'live';
  bool get hasGuest => guestId != null && guestId!.isNotEmpty;
}

class CoBroadcastRequest {
  final String id;
  final String fromUserId;
  final String toUserId;
  final String broadcastId;
  final String status;
  final DateTime createdAt;
  final String? fromUsername;
  final String? toUsername;

  CoBroadcastRequest({
    required this.id,
    required this.fromUserId,
    required this.toUserId,
    required this.broadcastId,
    required this.status,
    required this.createdAt,
    this.fromUsername,
    this.toUsername,
  });

  bool get isPending => status == 'pending';
}
