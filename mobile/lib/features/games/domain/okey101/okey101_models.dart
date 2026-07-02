import 'package:equatable/equatable.dart';

import '../../../../core/util/json_util.dart';

enum OkeyColor { red, yellow, blue, black, joker }

class Okey101Tile extends Equatable {
  const Okey101Tile({
    required this.id,
    required this.color,
    required this.value,
    this.isFakeJoker = false,
  });

  factory Okey101Tile.fromJson(Map<String, dynamic> json) {
    final colorRaw = pick(json, ['color'])?.toString() ?? 'red';
    return Okey101Tile(
      id: pick(json, ['id'])?.toString() ?? '',
      color: OkeyColor.values.firstWhere(
        (c) => c.name == colorRaw,
        orElse: () => OkeyColor.red,
      ),
      value: asInt(pick(json, ['value'])),
      isFakeJoker: pick(json, ['isFakeJoker']) == true,
    );
  }

  final String id;
  final OkeyColor color;
  final int value;
  final bool isFakeJoker;

  bool isWild(Okey101Tile? okey) {
    if (isFakeJoker || color == OkeyColor.joker) return true;
    if (okey == null) return false;
    return color == okey.color && value == okey.value;
  }

  int points(Okey101Tile? okey) => isWild(okey) ? 10 : value;

  @override
  List<Object?> get props => [id, color, value, isFakeJoker];
}

class Okey101PlayerView extends Equatable {
  const Okey101PlayerView({
    required this.userId,
    required this.displayName,
    required this.seat,
    required this.handCount,
    required this.opened,
    required this.penalty,
    required this.isMe,
    this.hand = const [],
  });

  factory Okey101PlayerView.fromJson(Map<String, dynamic> json) {
    final handRaw = json['hand'];
    final hand = handRaw is List
        ? handRaw
            .whereType<Map>()
            .map((e) => Okey101Tile.fromJson(Map<String, dynamic>.from(e)))
            .where((t) => t.id.isNotEmpty)
            .toList()
        : const <Okey101Tile>[];
    return Okey101PlayerView(
      userId: pick(json, ['userId'])?.toString() ?? '',
      displayName:
          pick(json, ['displayName', 'name'])?.toString() ?? 'Oyuncu',
      seat: asInt(pick(json, ['seat'])),
      handCount: asInt(pick(json, ['handCount'])) == 0
          ? hand.length
          : asInt(pick(json, ['handCount'])),
      opened: pick(json, ['opened']) == true,
      penalty: asInt(pick(json, ['penalty'])),
      isMe: pick(json, ['isMe']) == true,
      hand: hand,
    );
  }

  final String userId;
  final String displayName;
  final int seat;
  final int handCount;
  final bool opened;
  final int penalty;
  final bool isMe;
  final List<Okey101Tile> hand;

  @override
  List<Object?> get props =>
      [userId, displayName, seat, handCount, opened, penalty, isMe, hand];
}

class Okey101PublicState extends Equatable {
  const Okey101PublicState({
    this.phase = 'waiting',
    this.status = '',
    this.openScoreTarget = 101,
    this.maxPlayers = 4,
    this.minPlayers = 2,
    this.indicator,
    this.okey,
    this.deckCount = 0,
    this.discardTop,
    this.discardCount = 0,
    this.turnUserId,
    this.turnName,
    this.winnerId,
    this.winnerName,
    this.lastMove,
    this.hostUserId,
    this.myHandPoints = 0,
    this.players = const [],
  });

  factory Okey101PublicState.fromJson(Map<String, dynamic>? json) {
    if (json == null || json.isEmpty) return const Okey101PublicState();
    Okey101Tile? tileFrom(dynamic raw) {
      if (raw is! Map) return null;
      final t = Okey101Tile.fromJson(Map<String, dynamic>.from(raw));
      return t.id.isEmpty ? null : t;
    }

    final playersRaw = json['players'];
    final players = playersRaw is List
        ? playersRaw
            .whereType<Map>()
            .map((e) => Okey101PlayerView.fromJson(Map<String, dynamic>.from(e)))
            .toList()
        : const <Okey101PlayerView>[];

    return Okey101PublicState(
      phase: pick(json, ['phase', 'status'])?.toString() ?? 'waiting',
      status: pick(json, ['status'])?.toString() ?? '',
      openScoreTarget: asInt(pick(json, ['openScoreTarget'])) == 0
          ? 101
          : asInt(pick(json, ['openScoreTarget'])),
      maxPlayers: asInt(pick(json, ['maxPlayers'])) == 0
          ? 4
          : asInt(pick(json, ['maxPlayers'])),
      minPlayers: asInt(pick(json, ['minPlayers'])) == 0
          ? 2
          : asInt(pick(json, ['minPlayers'])),
      indicator: tileFrom(json['indicator']),
      okey: tileFrom(json['okey']),
      deckCount: asInt(pick(json, ['deckCount'])),
      discardTop: tileFrom(json['discardTop']),
      discardCount: asInt(pick(json, ['discardCount'])),
      turnUserId: pick(json, ['turnUserId'])?.toString(),
      turnName: pick(json, ['turnName'])?.toString(),
      winnerId: pick(json, ['winnerId'])?.toString(),
      winnerName: pick(json, ['winnerName'])?.toString(),
      lastMove: pick(json, ['lastMove'])?.toString(),
      hostUserId: pick(json, ['hostUserId'])?.toString(),
      myHandPoints: asInt(pick(json, ['myHandPoints'])),
      players: players,
    );
  }

  Okey101PlayerView? get me {
    for (final p in players) {
      if (p.isMe) return p;
    }
    return null;
  }

  bool isMyTurn(String? userId) =>
      userId != null && turnUserId != null && turnUserId == userId;

  final String phase;
  final String status;
  final int openScoreTarget;
  final int maxPlayers;
  final int minPlayers;
  final Okey101Tile? indicator;
  final Okey101Tile? okey;
  final int deckCount;
  final Okey101Tile? discardTop;
  final int discardCount;
  final String? turnUserId;
  final String? turnName;
  final String? winnerId;
  final String? winnerName;
  final String? lastMove;
  final String? hostUserId;
  final int myHandPoints;
  final List<Okey101PlayerView> players;

  @override
  List<Object?> get props => [
        phase,
        status,
        openScoreTarget,
        maxPlayers,
        minPlayers,
        indicator,
        okey,
        deckCount,
        discardTop,
        discardCount,
        turnUserId,
        turnName,
        winnerId,
        winnerName,
        lastMove,
        hostUserId,
        myHandPoints,
        players,
      ];
}

Okey101PublicState? parseOkey101FromRoomRaw(Map<String, dynamic> raw) {
  final nested = raw['okey101'];
  if (nested is Map) {
    return Okey101PublicState.fromJson(Map<String, dynamic>.from(nested));
  }
  if (raw['gameType']?.toString() == 'okey101') {
    return Okey101PublicState.fromJson(raw);
  }
  return null;
}
