import '../../../core/util/json_util.dart';

int _intOr(dynamic v, int fallback) {
  final n = asInt(v);
  return n > 0 ? n : fallback;
}

/// PK durumları — `PK_ENTEGRASYON.md` §7.
enum PkStatus {
  pending,
  starting,
  active,
  paused,
  completed,
  cancelled,
  rejected,
  expired,
  unknown;

  static PkStatus parse(String? raw) {
    switch (raw?.toLowerCase().trim()) {
      case 'pending':
        return PkStatus.pending;
      case 'starting':
        return PkStatus.starting;
      case 'active':
        return PkStatus.active;
      case 'paused':
        return PkStatus.paused;
      case 'completed':
        return PkStatus.completed;
      case 'cancelled':
        return PkStatus.cancelled;
      case 'rejected':
        return PkStatus.rejected;
      case 'expired':
        return PkStatus.expired;
      default:
        return PkStatus.unknown;
    }
  }

  bool get isTerminal =>
      this == completed ||
      this == cancelled ||
      this == rejected ||
      this == expired;

  bool get isLive =>
      this == pending ||
      this == starting ||
      this == active ||
      this == paused;
}

class PkParticipant {
  const PkParticipant({
    required this.id,
    this.name = '',
    this.image = '',
  });

  final String id;
  final String name;
  final String image;

  factory PkParticipant.fromJson(Map<String, dynamic> json) {
    return PkParticipant(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      image: json['image']?.toString() ?? '',
    );
  }
}

class PkBattle {
  const PkBattle({
    required this.id,
    required this.status,
    this.room1Id = '',
    this.room2Id = '',
    this.user1Id = '',
    this.user2Id = '',
    this.score1 = 0,
    this.score2 = 0,
    this.duration = 180,
    this.startedAt = '',
    this.endedAt = '',
    this.winnerId = '',
    this.createdAt = '',
    this.endsAt = '',
    this.expiresAt = '',
    this.serverNow = '',
    this.user1,
    this.user2,
    this.isDraw = false,
  });

  final String id;
  final PkStatus status;
  final String room1Id;
  final String room2Id;
  final String user1Id;
  final String user2Id;
  final int score1;
  final int score2;
  final int duration;
  final String startedAt;
  final String endedAt;
  final String winnerId;
  final String createdAt;
  final String endsAt;
  final String expiresAt;
  final String serverNow;
  final PkParticipant? user1;
  final PkParticipant? user2;
  final bool isDraw;

  factory PkBattle.fromJson(Map<String, dynamic> json) {
    final u1 = json['user1'];
    final u2 = json['user2'];
    return PkBattle(
      id: json['id']?.toString() ?? '',
      status: PkStatus.parse(json['status']?.toString()),
      room1Id: json['room1Id']?.toString() ?? '',
      room2Id: json['room2Id']?.toString() ?? '',
      user1Id: json['user1Id']?.toString() ?? '',
      user2Id: json['user2Id']?.toString() ?? '',
      score1: asInt(json['score1']),
      score2: asInt(json['score2']),
      duration: _intOr(json['duration'], 180),
      startedAt: json['startedAt']?.toString() ?? '',
      endedAt: json['endedAt']?.toString() ?? '',
      winnerId: json['winnerId']?.toString() ?? '',
      createdAt: json['createdAt']?.toString() ?? '',
      endsAt: (json['endsAt'] ?? json['endTime'])?.toString() ?? '',
      expiresAt: json['expiresAt']?.toString() ?? '',
      serverNow: json['serverNow']?.toString() ?? '',
      user1: u1 is Map ? PkParticipant.fromJson(asJsonMap(u1)) : null,
      user2: u2 is Map ? PkParticipant.fromJson(asJsonMap(u2)) : null,
      isDraw: json['isDraw'] == true,
    );
  }

  Duration? remainingInvite(Duration clockSkew) {
    final expiry = DateTime.tryParse(expiresAt);
    final server = DateTime.tryParse(serverNow);
    if (expiry == null) return null;
    final now = server != null
        ? DateTime.now().add(clockSkew)
        : DateTime.now();
    return expiry.difference(now);
  }

  Duration? remainingBattle(Duration clockSkew) {
    final end = DateTime.tryParse(endsAt);
    final server = DateTime.tryParse(serverNow);
    if (end == null) return null;
    final now = server != null
        ? DateTime.now().add(clockSkew)
        : DateTime.now();
    return end.difference(now);
  }
}

class PkCandidate {
  const PkCandidate({
    required this.contextId,
    this.userId = '',
    this.name = '',
    this.image = '',
    this.title = '',
    this.viewers = 0,
  });

  final String contextId;
  final String userId;
  final String name;
  final String image;
  final String title;
  final int viewers;

  factory PkCandidate.fromStreamJson(Map<String, dynamic> json) {
    return PkCandidate(
      contextId: json['streamId']?.toString() ?? '',
      userId: json['userId']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      image: json['image']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      viewers: asInt(json['viewers']),
    );
  }

  factory PkCandidate.fromRoomJson(Map<String, dynamic> json) {
    return PkCandidate(
      contextId: json['roomId']?.toString() ?? json['id']?.toString() ?? '',
      userId: json['ownerId']?.toString() ?? json['userId']?.toString() ?? '',
      name: json['name']?.toString() ?? json['title']?.toString() ?? '',
      image: json['image']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      viewers: asInt(json['listeners'] ?? json['viewers']),
    );
  }
}

class PkCandidatesBundle {
  const PkCandidatesBundle({
    required this.candidates,
    this.selfBusy = false,
    this.total = 0,
  });

  final List<PkCandidate> candidates;
  final bool selfBusy;
  final int total;
}

class PkEvent {
  const PkEvent({
    required this.battleId,
    required this.action,
    this.status,
    this.serverNow = '',
    this.raw = const {},
  });

  final String battleId;
  final String action;
  final PkStatus? status;
  final String serverNow;
  final Map<String, dynamic> raw;

  factory PkEvent.fromJson(Map<String, dynamic> json) {
    return PkEvent(
      battleId: json['battleId']?.toString() ?? json['id']?.toString() ?? '',
      action: json['action']?.toString() ?? json['type']?.toString() ?? '',
      status: PkStatus.parse(json['status']?.toString()),
      serverNow: json['serverNow']?.toString() ?? '',
      raw: json,
    );
  }
}

/// İzinli durum geçişleri (istemci doğrulama / test).
bool pkTransitionAllowed(PkStatus from, PkStatus to) {
  switch (from) {
    case PkStatus.pending:
      return to == PkStatus.starting ||
          to == PkStatus.active ||
          to == PkStatus.rejected ||
          to == PkStatus.cancelled ||
          to == PkStatus.expired;
    case PkStatus.starting:
      return to == PkStatus.active ||
          to == PkStatus.cancelled ||
          to == PkStatus.expired;
    case PkStatus.active:
      return to == PkStatus.paused || to == PkStatus.completed;
    case PkStatus.paused:
      return to == PkStatus.active || to == PkStatus.completed;
    default:
      return false;
  }
}
