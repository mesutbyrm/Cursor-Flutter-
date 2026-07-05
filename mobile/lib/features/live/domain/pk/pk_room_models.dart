import '../../../../core/util/json_util.dart';

/// PK Faz 2 modları — birleşik `/api/pk/*` sözleşmesi.
enum PkRoomMode {
  oneVsOne,
  team,
  guest;

  static PkRoomMode parse(String? v) {
    switch ((v ?? '').toLowerCase()) {
      case 'team':
        return PkRoomMode.team;
      case 'guest':
        return PkRoomMode.guest;
      default:
        return PkRoomMode.oneVsOne;
    }
  }

  String get wire => switch (this) {
        PkRoomMode.team => 'team',
        PkRoomMode.guest => 'guest',
        PkRoomMode.oneVsOne => '1v1',
      };
}

/// Bir PK koltuğu — çoklu misafir/takım. `PkSeat` (userId, team, score, status).
class PkSeat {
  const PkSeat({
    required this.seatIndex,
    this.userId,
    this.team,
    this.score = 0,
    this.status = 'active',
    this.displayName,
    this.avatarUrl,
    this.streamId,
    this.isHost = false,
  });

  factory PkSeat.fromJson(Map<String, dynamic> json) {
    return PkSeat(
      seatIndex: asInt(pick(json, ['seatIndex', 'index', 'position', 'slot'])),
      userId: pick(json, ['userId', 'id'])?.toString(),
      team: pick(json, ['team', 'side'])?.toString(),
      score: asInt(pick(json, ['score', 'coins', 'points'])),
      status: (pick(json, ['status']) ?? 'active').toString(),
      displayName:
          pick(json, ['displayName', 'name', 'username', 'nickname'])?.toString(),
      avatarUrl: pick(json, ['avatarUrl', 'avatar', 'image'])?.toString(),
      streamId: pick(json, ['streamId'])?.toString(),
      isHost: pick(json, ['isHost', 'host']) == true,
    );
  }

  final int seatIndex;
  final String? userId;
  final String? team; // left | right | null
  final int score;
  final String status; // active | left | kicked
  final String? displayName;
  final String? avatarUrl;
  final String? streamId;
  final bool isHost;

  bool get isOccupied =>
      userId != null && userId!.isNotEmpty && status == 'active';
  bool get isLeft => (team ?? '').toLowerCase() == 'left';
  bool get isRight => (team ?? '').toLowerCase() == 'right';

  PkSeat copyWith({int? score, String? status}) => PkSeat(
        seatIndex: seatIndex,
        userId: userId,
        team: team,
        score: score ?? this.score,
        status: status ?? this.status,
        displayName: displayName,
        avatarUrl: avatarUrl,
        streamId: streamId,
        isHost: isHost,
      );
}

/// Çoklu misafir / takım PK oturumu — `/api/pk/*`.
class PkRoomMatch {
  const PkRoomMatch({
    required this.id,
    required this.mode,
    required this.status,
    this.seatCount = 0,
    this.durationSec = 180,
    this.remainingSec = 0,
    this.leftScore = 0,
    this.rightScore = 0,
    this.leftName = 'Sol',
    this.rightName = 'Sağ',
    this.hostUserId,
    this.hostStreamId,
    this.winnerSide,
    this.winnerSeatIndex,
    this.seats = const [],
  });

  factory PkRoomMatch.fromJson(Map<String, dynamic> json) {
    final m = json['match'] is Map ? asJsonMap(json['match']) : json;
    final seatsRaw = pick(m, ['seats', 'participants']);
    final seats = <PkSeat>[];
    if (seatsRaw is List) {
      for (final e in seatsRaw) {
        if (e is Map) seats.add(PkSeat.fromJson(asJsonMap(e)));
      }
    }
    seats.sort((a, b) => a.seatIndex.compareTo(b.seatIndex));

    var remaining = asInt(pick(m, ['remainingSec', 'secondsLeft', 'remaining']));
    final endsAtRaw = pick(m, ['endsAt', 'endAt', 'finishAt']);
    if (remaining <= 0 && endsAtRaw != null) {
      final endsAt = DateTime.tryParse(endsAtRaw.toString());
      if (endsAt != null) {
        remaining = endsAt.difference(DateTime.now()).inSeconds;
        if (remaining < 0) remaining = 0;
      }
    }

    return PkRoomMatch(
      id: (pick(m, ['id', 'matchId', 'pkMatchId']) ?? '').toString(),
      mode: PkRoomMode.parse(pick(m, ['mode'])?.toString()),
      status: (pick(m, ['status']) ?? 'pending').toString(),
      seatCount: asInt(pick(m, ['seatCount', 'seats_count', 'maxSeats'])),
      durationSec: () {
        final d = asInt(pick(m, ['durationSec', 'duration']));
        return d > 0 ? d : 180;
      }(),
      remainingSec: remaining,
      leftScore: asInt(pick(m, ['leftScore', 'challengerScore'])),
      rightScore: asInt(pick(m, ['rightScore', 'opponentScore'])),
      leftName: (pick(m, ['leftName']) ?? 'Sol').toString(),
      rightName: (pick(m, ['rightName']) ?? 'Sağ').toString(),
      hostUserId: pick(m, ['hostUserId', 'hostId'])?.toString(),
      hostStreamId: pick(m, ['hostStreamId'])?.toString(),
      winnerSide: pick(m, ['winnerSide', 'result', 'winner'])?.toString(),
      winnerSeatIndex: m.containsKey('winnerSeatIndex')
          ? asInt(pick(m, ['winnerSeatIndex']))
          : null,
      seats: seats,
    );
  }

  final String id;
  final PkRoomMode mode;
  final String status; // pending | live | completed | cancelled
  final int seatCount;
  final int durationSec;
  final int remainingSec;
  final int leftScore;
  final int rightScore;
  final String leftName;
  final String rightName;
  final String? hostUserId;
  final String? hostStreamId;
  final String? winnerSide; // left_win | right_win | draw
  final int? winnerSeatIndex;
  final List<PkSeat> seats;

  bool get isPending => status == 'pending';
  bool get isLive => status == 'live' || status == 'active';
  bool get isCompleted =>
      status == 'completed' || status == 'ended' || status == 'cancelled';
  bool get isLastCall => isLive && remainingSec <= 30;

  bool get isTeam => mode == PkRoomMode.team;
  bool get isGuest => mode == PkRoomMode.guest;

  List<PkSeat> get activeSeats => seats.where((s) => s.isOccupied).toList();
  List<PkSeat> get leftSeats => activeSeats.where((s) => s.isLeft).toList();
  List<PkSeat> get rightSeats => activeSeats.where((s) => s.isRight).toList();

  /// Guest modunda kazanan koltuk (en yüksek skor).
  PkSeat? get topSeat {
    if (activeSeats.isEmpty) return null;
    return activeSeats.reduce((a, b) => a.score >= b.score ? a : b);
  }

  int get totalScore => isTeam
      ? (leftScore + rightScore)
      : activeSeats.fold(0, (sum, s) => sum + s.score);
}

/// PK geçmişi satırı — `/api/pk/me/history`.
class PkHistoryEntry {
  const PkHistoryEntry({
    required this.id,
    required this.result,
    this.mode = PkRoomMode.oneVsOne,
    this.opponentName,
    this.myScore = 0,
    this.opponentScore = 0,
    this.coins = 0,
    this.durationSec = 0,
    this.at,
  });

  factory PkHistoryEntry.fromJson(Map<String, dynamic> json) {
    return PkHistoryEntry(
      id: (pick(json, ['id', 'matchId']) ?? '').toString(),
      result:
          (pick(json, ['result', 'outcome']) ?? 'draw').toString().toLowerCase(),
      mode: PkRoomMode.parse(pick(json, ['mode'])?.toString()),
      opponentName: pick(json,
              ['opponentName', 'opponent', 'rightName', 'vs', 'against'])
          ?.toString(),
      myScore: asInt(pick(json, ['myScore', 'score', 'leftScore', 'challengerScore'])),
      opponentScore:
          asInt(pick(json, ['opponentScore', 'rightScore'])),
      coins: asInt(pick(json, ['coins', 'totalCoins', 'jeton', 'earned'])),
      durationSec: asInt(pick(json, ['durationSec', 'duration'])),
      at: DateTime.tryParse(
          pick(json, ['at', 'createdAt', 'endedAt', 'date'])?.toString() ?? ''),
    );
  }

  final String id;
  final String result; // win | loss | draw
  final PkRoomMode mode;
  final String? opponentName;
  final int myScore;
  final int opponentScore;
  final int coins;
  final int durationSec;
  final DateTime? at;

  bool get isWin => result == 'win' || result == 'won';
  bool get isLoss => result == 'loss' || result == 'lose' || result == 'lost';
  bool get isDraw => !isWin && !isLoss;
}
