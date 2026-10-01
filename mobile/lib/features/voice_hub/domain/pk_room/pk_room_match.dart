import 'pk_wire_event.dart';

/// Oda içi PK yaşam döngüsü (istemci durum makinesi).
///
/// Sunucu `status` → faz: `pending/invited`→[invited], `accepted`→[accepted],
/// `starting`→[starting], `active`→[active], `paused`→[paused],
/// `completed/cancelled/rejected/expired`→[finished]. [finishing] yalnızca
/// yereldir (süre doldu / "PK Bitir" basıldı; sunucu onayı bekleniyor).
enum PkRoomPhase {
  idle,
  invited,
  accepted,
  starting,
  active,
  paused,
  finishing,
  finished,
}

extension PkRoomPhaseX on PkRoomPhase {
  /// PK arayüzü gösterilmeli mi? (`finishing`/`finished`/`idle` → normal oda.)
  bool get showsOverlay =>
      this == PkRoomPhase.starting ||
      this == PkRoomPhase.active ||
      this == PkRoomPhase.paused;

  bool get isTerminal => this == PkRoomPhase.finished;
}

PkRoomPhase pkRoomPhaseFromStatus(String? status) {
  switch ((status ?? '').toLowerCase().trim()) {
    case 'pending':
    case 'invited':
    case 'created':
    case 'waiting':
      return PkRoomPhase.invited;
    case 'accepted':
      return PkRoomPhase.accepted;
    case 'starting':
    case 'countdown':
    case 'preparing':
      return PkRoomPhase.starting;
    case 'active':
    case 'live':
    case 'started':
    case 'running':
    case 'in_progress':
      return PkRoomPhase.active;
    case 'paused':
      return PkRoomPhase.paused;
    case 'completed':
    case 'ended':
    case 'cancelled':
    case 'canceled':
    case 'rejected':
    case 'expired':
      return PkRoomPhase.finished;
  }
  return PkRoomPhase.idle;
}

/// PK takım üyesi (1 = Takım 1, 2 = Takım 2).
class PkRoomMember {
  const PkRoomMember({
    required this.userId,
    required this.side,
    this.name,
    this.avatarUrl,
    this.points = 0,
    this.isCaptain = false,
    this.seatNumber,
  });

  final String userId;
  final int side;
  final String? name;
  final String? avatarUrl;
  final int points;
  final bool isCaptain;
  final int? seatNumber;

  String get displayName {
    final n = name?.trim() ?? '';
    return n.isNotEmpty ? n : 'Oyuncu';
  }

  PkRoomMember copyWith({int? points}) => PkRoomMember(
        userId: userId,
        side: side,
        name: name,
        avatarUrl: avatarUrl,
        points: points ?? this.points,
        isCaptain: isCaptain,
        seatNumber: seatNumber,
      );

  static PkRoomMember? fromJson(Map<String, dynamic> j, {int fallbackSide = 0}) {
    final id = (j['userId'] ?? j['id'])?.toString().trim() ?? '';
    if (id.isEmpty) return null;
    final side = _int(j['side'], fallback: fallbackSide);
    if (side != 1 && side != 2) return null;
    return PkRoomMember(
      userId: id,
      side: side,
      name: (j['name'] ?? j['displayName'] ?? j['username'])?.toString(),
      avatarUrl: (j['image'] ?? j['avatarUrl'])?.toString(),
      points: _int(j['points'] ?? j['score']),
      isCaptain: j['isCaptain'] == true,
      seatNumber: j['seatNumber'] is num ? (j['seatNumber'] as num).toInt() : null,
    );
  }
}

/// Oda içi PK maçının TEK doğruluk kaynağı modeli (sunucu kanonik).
///
/// Süre `endsAt`'tan (sunucu zamanı) türetilir; cihaz saatine güvenilmez.
class PkRoomMatch {
  const PkRoomMatch({
    required this.battleId,
    required this.roomId,
    required this.status,
    required this.phase,
    this.scope = 'room_user',
    this.mode = '1v1',
    this.durationSec = 180,
    this.countdownSec = 0,
    this.startedAt,
    this.endsAt,
    this.pausedAt,
    this.remainingMsAtPause,
    this.score1 = 0,
    this.score2 = 0,
    this.members = const [],
    this.winnerSide,
    this.isDraw = false,
    this.endReason,
    this.startingUntil,
  });

  final String battleId;
  final String roomId;
  final String status;
  final PkRoomPhase phase;
  final String scope;
  final String mode;
  final int durationSec;
  final int countdownSec;
  final DateTime? startedAt;
  final DateTime? endsAt;
  final DateTime? pausedAt;
  final int? remainingMsAtPause;
  final int score1;
  final int score2;
  final List<PkRoomMember> members;
  final int? winnerSide;
  final bool isDraw;
  final String? endReason;

  /// `starting` fazında geri sayımın biteceği SUNUCU zamanı (yerel hesap).
  final DateTime? startingUntil;

  bool get isLive => phase.showsOverlay || phase == PkRoomPhase.finishing;

  List<PkRoomMember> team(int side) =>
      members.where((m) => m.side == side).toList(growable: false);

  int sideOf(String? userId) {
    final id = userId?.trim() ?? '';
    if (id.isEmpty) return 0;
    for (final m in members) {
      if (m.userId == id) return m.side;
    }
    return 0;
  }

  int scoreOf(int side) => side == 1 ? score1 : score2;

  /// Sunucu zamanı [serverNow] için kalan süre (ms). `active`: `endsAt - now`;
  /// `paused`: duraklatma anındaki kalan; `starting`: tam süre.
  int remainingMsAt(DateTime serverNow) {
    switch (phase) {
      case PkRoomPhase.active:
      case PkRoomPhase.finishing:
        final end = endsAt;
        if (end == null) return durationSec * 1000;
        final ms = end.toUtc().difference(serverNow.toUtc()).inMilliseconds;
        return ms < 0 ? 0 : ms;
      case PkRoomPhase.paused:
        if (remainingMsAtPause != null) {
          return remainingMsAtPause!.clamp(0, 86400000);
        }
        final end = endsAt;
        final at = pausedAt;
        if (end != null && at != null) {
          final ms = end.toUtc().difference(at.toUtc()).inMilliseconds;
          return ms < 0 ? 0 : ms;
        }
        return durationSec * 1000;
      default:
        return durationSec * 1000;
    }
  }

  PkRoomMatch copyWith({
    PkRoomPhase? phase,
    String? status,
    int? score1,
    int? score2,
    List<PkRoomMember>? members,
    DateTime? endsAt,
    DateTime? startingUntil,
  }) {
    return PkRoomMatch(
      battleId: battleId,
      roomId: roomId,
      status: status ?? this.status,
      phase: phase ?? this.phase,
      scope: scope,
      mode: mode,
      durationSec: durationSec,
      countdownSec: countdownSec,
      startedAt: startedAt,
      endsAt: endsAt ?? this.endsAt,
      pausedAt: pausedAt,
      remainingMsAtPause: remainingMsAtPause,
      score1: score1 ?? this.score1,
      score2: score2 ?? this.score2,
      members: members ?? this.members,
      winnerSide: winnerSide,
      isDraw: isDraw,
      endReason: endReason,
      startingUntil: startingUntil ?? this.startingUntil,
    );
  }

  /// Hediye puanı yaması: yalnızca skorları (ve alıcı üyenin puanını) günceller;
  /// faz/süre/üyeler DEĞİŞMEZ. Backend skoru kanoniktir (`score1/score2` mutlak).
  PkRoomMatch withScorePatch({
    required int score1,
    required int score2,
    String? receiverId,
    int addedAmount = 0,
  }) {
    var next = members;
    final rid = receiverId?.trim() ?? '';
    if (rid.isNotEmpty && addedAmount > 0) {
      next = [
        for (final m in members)
          m.userId == rid ? m.copyWith(points: m.points + addedAmount) : m,
      ];
    }
    return copyWith(score1: score1, score2: score2, members: next);
  }

  /// Sunucu payload'ından (REST GET / SSE) model üretir. [previous] aynı maça
  /// aitse eksik alanlar (üyeler, `endsAt`, `startedAt`) ondan korunur —
  /// kısmi olaylar (PK_PAUSED vb.) maçı sıfırlamaz.
  static PkRoomMatch? fromJson(
    Map<String, dynamic> j, {
    PkRoomMatch? previous,
    String roomIdFallback = '',
    DateTime? serverNow,
  }) {
    final data = PkWireEvent.parse(j).raw;
    final id = (data['battleId'] ?? data['matchId'] ?? data['pkBattleId'] ?? data['id'])
            ?.toString()
            .trim() ??
        '';
    if (id.isEmpty) return null;
    final prev = previous != null && previous.battleId == id ? previous : null;

    final kind = PkWireEvent.classify(data);
    var status = data['status']?.toString().toLowerCase().trim() ?? '';
    // Tip → durum (payload status taşımıyorsa).
    if (status.isEmpty) {
      status = switch (kind) {
        PkWireKind.starting => 'starting',
        PkWireKind.started || PkWireKind.resumed => 'active',
        PkWireKind.paused => 'paused',
        PkWireKind.ended => 'completed',
        PkWireKind.cancelled => 'cancelled',
        PkWireKind.rejected => 'rejected',
        PkWireKind.expired => 'expired',
        _ => prev?.status ?? '',
      };
    }
    if (status == 'live') status = 'active';

    final endsAt = _date(data['endsAt'] ?? data['endTime'] ?? data['endAt']) ?? prev?.endsAt;
    final startedAt = _date(data['startedAt'] ?? data['startAt']) ?? prev?.startedAt;
    final pausedAt = _date(data['pausedAt']) ?? (status == 'paused' ? prev?.pausedAt : null);
    final duration = _int(data['duration'] ?? data['durationSec'] ?? data['durationSeconds'],
        fallback: prev?.durationSec ?? 180);
    final countdown = _int(data['countdownSec'], fallback: prev?.countdownSec ?? 0);

    var phase = pkRoomPhaseFromStatus(status);
    // Yerel 'finishing' bir sonraki sunucu durumu gelene kadar korunur.
    if (prev != null &&
        prev.phase == PkRoomPhase.finishing &&
        (phase == PkRoomPhase.active)) {
      phase = PkRoomPhase.finishing;
    }

    final members = _members(data, prev);
    final roomId = (data['scopeRoomId'] ??
                data['room1Id'] ??
                data['stream1Id'] ??
                prev?.roomId ??
                roomIdFallback)
            .toString()
            .trim();

    DateTime? startingUntil = prev?.startingUntil;
    if (phase == PkRoomPhase.starting && startingUntil == null && countdown > 0) {
      startingUntil = (serverNow ?? DateTime.now().toUtc()).add(Duration(seconds: countdown));
    }
    if (phase != PkRoomPhase.starting) startingUntil = null;

    return PkRoomMatch(
      battleId: id,
      roomId: roomId,
      status: status,
      phase: phase,
      scope: data['scope']?.toString() ?? prev?.scope ?? 'room_user',
      mode: data['mode']?.toString() ?? prev?.mode ?? '1v1',
      durationSec: duration,
      countdownSec: countdown,
      startedAt: startedAt,
      endsAt: endsAt,
      pausedAt: pausedAt,
      remainingMsAtPause: data['remainingMs'] is num
          ? (data['remainingMs'] as num).toInt()
          : (status == 'paused' ? prev?.remainingMsAtPause : null),
      score1: data.containsKey('score1') ? _int(data['score1']) : (prev?.score1 ?? 0),
      score2: data.containsKey('score2') ? _int(data['score2']) : (prev?.score2 ?? 0),
      members: members,
      winnerSide: data['winnerSide'] is num
          ? (data['winnerSide'] as num).toInt()
          : prev?.winnerSide,
      isDraw: data['isDraw'] == true || (prev?.isDraw ?? false),
      endReason: data['reason']?.toString() ?? prev?.endReason,
      startingUntil: startingUntil,
    );
  }

  static List<PkRoomMember> _members(Map<String, dynamic> data, PkRoomMatch? prev) {
    final raw = data['participants'] ?? data['pkParticipants'];
    if (raw is List) {
      final out = <PkRoomMember>[];
      for (final e in raw) {
        if (e is! Map) continue;
        final m = PkRoomMember.fromJson(Map<String, dynamic>.from(e));
        if (m != null) out.add(m);
      }
      if (out.isNotEmpty) {
        // Aynı kullanıcı iki kez gelirse ilkini tut.
        final seen = <String>{};
        return [
          for (final m in out)
            if (seen.add(m.userId)) m,
        ];
      }
    }
    if (prev != null && prev.members.isNotEmpty) return prev.members;

    // 1v1 yedek: user1 / user2.
    final out = <PkRoomMember>[];
    void addUser(dynamic user, dynamic fallbackId, int side) {
      if (user is Map) {
        final m = Map<String, dynamic>.from(user);
        final id = (m['id'] ?? m['userId'] ?? fallbackId)?.toString().trim() ?? '';
        if (id.isEmpty) return;
        out.add(PkRoomMember(
          userId: id,
          side: side,
          name: (m['name'] ?? m['username'])?.toString(),
          avatarUrl: (m['image'] ?? m['avatarUrl'])?.toString(),
          isCaptain: true,
        ));
        return;
      }
      final id = fallbackId?.toString().trim() ?? '';
      if (id.isNotEmpty) {
        out.add(PkRoomMember(userId: id, side: side, isCaptain: true));
      }
    }

    addUser(data['user1'], data['user1Id'], 1);
    addUser(data['user2'], data['user2Id'], 2);
    return out;
  }

  static DateTime? _date(dynamic raw) {
    if (raw == null) return null;
    if (raw is DateTime) return raw.toUtc();
    final s = raw.toString().trim();
    if (s.isEmpty) return null;
    return DateTime.tryParse(s)?.toUtc();
  }
}

int _int(dynamic v, {int fallback = 0}) {
  if (v is int) return v;
  if (v is num) return v.toInt();
  return int.tryParse('$v') ?? fallback;
}
