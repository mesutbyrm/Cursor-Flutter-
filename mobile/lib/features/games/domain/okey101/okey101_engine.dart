import 'dart:math';

import 'okey101_models.dart';

enum Okey101MoveType { start, draw, takeDiscard, discard, open }

class Okey101Move {
  const Okey101Move._(this.type, {this.tileId});

  const Okey101Move.start() : this._(Okey101MoveType.start);
  const Okey101Move.draw() : this._(Okey101MoveType.draw);
  const Okey101Move.takeDiscard() : this._(Okey101MoveType.takeDiscard);
  const Okey101Move.open() : this._(Okey101MoveType.open);
  const Okey101Move.discard(String tileId)
      : this._(Okey101MoveType.discard, tileId: tileId);

  factory Okey101Move.fromJson(Map<String, dynamic> json) {
    final type = json['type']?.toString() ?? 'draw';
    switch (type) {
      case 'start':
        return const Okey101Move.start();
      case 'draw':
        return const Okey101Move.draw();
      case 'takeDiscard':
        return const Okey101Move.takeDiscard();
      case 'open':
        return const Okey101Move.open();
      case 'discard':
        return Okey101Move.discard(json['tileId']?.toString() ?? '');
      default:
        return const Okey101Move.draw();
    }
  }

  final Okey101MoveType type;
  final String? tileId;
}

class Okey101PlayerState {
  Okey101PlayerState({
    required this.userId,
    required this.displayName,
    required this.seat,
    List<Okey101Tile>? hand,
    this.opened = false,
    this.penalty = 0,
    this.connected = true,
    this.drewThisTurn = false,
  }) : hand = hand ?? [];

  final String userId;
  final String displayName;
  final int seat;
  final List<Okey101Tile> hand;
  bool opened;
  int penalty;
  bool connected;
  bool drewThisTurn;

  Okey101PlayerState copyWith({
    List<Okey101Tile>? hand,
    bool? opened,
    int? penalty,
    bool? drewThisTurn,
  }) {
    return Okey101PlayerState(
      userId: userId,
      displayName: displayName,
      seat: seat,
      hand: hand ?? this.hand,
      opened: opened ?? this.opened,
      penalty: penalty ?? this.penalty,
      connected: connected,
      drewThisTurn: drewThisTurn ?? this.drewThisTurn,
    );
  }
}

class Okey101GameState {
  Okey101GameState({
    required this.hostUserId,
    this.phase = 'waiting',
    this.status = 'waiting',
    this.openScoreTarget = 101,
    this.maxPlayers = 4,
    this.minPlayers = 2,
    this.indicator,
    this.okey,
    List<Okey101Tile>? deck,
    List<Okey101Tile>? discard,
    List<Okey101PlayerState>? players,
    this.turnIndex = 0,
    this.winnerId,
    this.winnerName,
    this.lastMove,
  })  : deck = deck ?? [],
        discard = discard ?? [],
        players = players ?? [];

  String phase;
  String status;
  final int openScoreTarget;
  final int maxPlayers;
  final int minPlayers;
  Okey101Tile? indicator;
  Okey101Tile? okey;
  List<Okey101Tile> deck;
  List<Okey101Tile> discard;
  List<Okey101PlayerState> players;
  int turnIndex;
  String? winnerId;
  String? winnerName;
  String? lastMove;
  final String hostUserId;
}

final _rng = Random();

List<Okey101Tile> _createDeck() {
  final tiles = <Okey101Tile>[];
  for (final color in [
    OkeyColor.red,
    OkeyColor.yellow,
    OkeyColor.blue,
    OkeyColor.black,
  ]) {
    for (var value = 1; value <= 13; value++) {
      tiles.add(Okey101Tile(id: '${color.name}-$value-a', color: color, value: value));
      tiles.add(Okey101Tile(id: '${color.name}-$value-b', color: color, value: value));
    }
  }
  tiles.add(
    const Okey101Tile(id: 'joker-fake-a', color: OkeyColor.joker, value: 0, isFakeJoker: true),
  );
  tiles.add(
    const Okey101Tile(id: 'joker-fake-b', color: OkeyColor.joker, value: 0, isFakeJoker: true),
  );
  tiles.shuffle(_rng);
  return tiles;
}

Okey101Tile _resolveOkey(Okey101Tile indicator) {
  if (indicator.isFakeJoker || indicator.color == OkeyColor.joker) {
    return const Okey101Tile(id: 'okey-wild', color: OkeyColor.red, value: 1);
  }
  final next = indicator.value == 13 ? 1 : indicator.value + 1;
  return Okey101Tile(
    id: 'okey-${indicator.color.name}-$next',
    color: indicator.color,
    value: next,
  );
}

int _handPoints(List<Okey101Tile> hand, Okey101Tile? okey) {
  return hand.fold(0, (sum, tile) => sum + tile.points(okey));
}

bool _hasBasicGroup(List<Okey101Tile> hand, Okey101Tile? okey) {
  final byColor = <String, List<int>>{};
  final byValue = <int, int>{};
  for (final tile in hand) {
    final wild = okey != null && tile.isWild(okey);
    final color = wild ? 'wild' : tile.color.name;
    final value = wild ? -1 : tile.value;
    if (color != 'wild') {
      byColor.putIfAbsent(color, () => []).add(value);
    }
    if (value > 0) {
      byValue[value] = (byValue[value] ?? 0) + 1;
    }
  }
  for (final values in byColor.values) {
    values.sort();
    var run = 1;
    for (var i = 1; i < values.length; i++) {
      if (values[i] == values[i - 1] + 1) {
        run++;
        if (run >= 3) return true;
      } else if (values[i] != values[i - 1]) {
        run = 1;
      }
    }
  }
  for (final count in byValue.values) {
    if (count >= 3) return true;
  }
  if (okey != null && hand.where((t) => t.isWild(okey)).length >= 2) {
    return true;
  }
  return false;
}

Okey101GameState createOkey101State(String hostUserId, String hostName) {
  return Okey101GameState(
    hostUserId: hostUserId,
    players: [
      Okey101PlayerState(
        userId: hostUserId,
        displayName: hostName,
        seat: 0,
      ),
    ],
  );
}

Okey101GameState addPlayer(
  Okey101GameState state,
  String userId,
  String displayName,
) {
  if (state.phase != 'waiting') {
    throw StateError('Oyun başlamış');
  }
  if (state.players.any((p) => p.userId == userId)) return state;
  if (state.players.length >= state.maxPlayers) {
    throw StateError('Oda dolu');
  }
  return Okey101GameState(
    hostUserId: state.hostUserId,
    phase: state.phase,
    status: state.status,
    openScoreTarget: state.openScoreTarget,
    maxPlayers: state.maxPlayers,
    minPlayers: state.minPlayers,
    indicator: state.indicator,
    okey: state.okey,
    deck: state.deck,
    discard: state.discard,
    players: [
      ...state.players,
      Okey101PlayerState(
        userId: userId,
        displayName: displayName,
        seat: state.players.length,
      ),
    ],
    turnIndex: state.turnIndex,
    winnerId: state.winnerId,
    winnerName: state.winnerName,
    lastMove: state.lastMove,
  );
}

Okey101GameState startGame(Okey101GameState state, String userId) {
  if (state.phase != 'waiting') throw StateError('Oyun zaten başladı');
  if (state.players.length < state.minPlayers) {
    throw StateError('En az ${state.minPlayers} oyuncu gerekli');
  }
  if (userId != state.hostUserId) {
    throw StateError('Yalnızca oda sahibi başlatabilir');
  }

  final deck = _createDeck();
  final indicator = deck.removeLast();
  final okey = _resolveOkey(indicator);

  final players = <Okey101PlayerState>[];
  for (var i = 0; i < state.players.length; i++) {
    final count = i == 0 ? 15 : 14;
    final hand = <Okey101Tile>[];
    for (var j = 0; j < count; j++) {
      hand.add(deck.removeLast());
    }
    players.add(state.players[i].copyWith(hand: hand, opened: false));
  }

  final discard = deck.isNotEmpty ? [deck.removeLast()] : <Okey101Tile>[];

  return Okey101GameState(
    hostUserId: state.hostUserId,
    phase: 'playing',
    status: 'playing',
    indicator: indicator,
    okey: okey,
    deck: deck,
    discard: discard,
    players: players,
    lastMove: 'Oyun başladı',
  );
}

Okey101GameState _applyPenalties(Okey101GameState state, String winnerId) {
  final players = state.players.map((p) {
    if (p.userId == winnerId) return p;
    return p.copyWith(penalty: p.penalty + _handPoints(p.hand, state.okey));
  }).toList();
  return Okey101GameState(
    hostUserId: state.hostUserId,
    phase: state.phase,
    status: state.status,
    openScoreTarget: state.openScoreTarget,
    maxPlayers: state.maxPlayers,
    minPlayers: state.minPlayers,
    indicator: state.indicator,
    okey: state.okey,
    deck: state.deck,
    discard: state.discard,
    players: players,
    turnIndex: state.turnIndex,
    winnerId: state.winnerId,
    winnerName: state.winnerName,
    lastMove: state.lastMove,
  );
}

Okey101GameState applyMove(
  Okey101GameState state,
  String userId,
  Okey101Move move,
) {
  if (move.type == Okey101MoveType.start) {
    return startGame(state, userId);
  }
  if (state.phase != 'playing') throw StateError('Oyun aktif değil');

  final playerIndex = state.players.indexWhere((p) => p.userId == userId);
  if (playerIndex < 0) throw StateError('Oyuncu değilsiniz');
  if (playerIndex != state.turnIndex) throw StateError('Sıra sizde değil');

  final player = state.players[playerIndex];
  final okey = state.okey;

  switch (move.type) {
    case Okey101MoveType.draw:
      if (player.drewThisTurn) throw StateError('Bu turda zaten çektiniz');
      if (state.deck.isEmpty) throw StateError('Deste bitti');
      final drawn = state.deck.removeLast();
      final players = [...state.players];
      players[playerIndex] = player.copyWith(
        hand: [...player.hand, drawn],
        drewThisTurn: true,
      );
      return Okey101GameState(
        hostUserId: state.hostUserId,
        phase: state.phase,
        status: state.status,
        openScoreTarget: state.openScoreTarget,
        maxPlayers: state.maxPlayers,
        minPlayers: state.minPlayers,
        indicator: state.indicator,
        okey: state.okey,
        deck: state.deck,
        discard: state.discard,
        players: players,
        turnIndex: state.turnIndex,
        lastMove: '${player.displayName} desteden çekti',
      );

    case Okey101MoveType.takeDiscard:
      if (player.drewThisTurn) throw StateError('Bu turda zaten çektiniz');
      if (state.discard.isEmpty) throw StateError('Atık yok');
      final taken = state.discard.removeLast();
      final takePlayers = [...state.players];
      takePlayers[playerIndex] = player.copyWith(
        hand: [...player.hand, taken],
        drewThisTurn: true,
      );
      return Okey101GameState(
        hostUserId: state.hostUserId,
        phase: state.phase,
        status: state.status,
        openScoreTarget: state.openScoreTarget,
        maxPlayers: state.maxPlayers,
        minPlayers: state.minPlayers,
        indicator: state.indicator,
        okey: state.okey,
        deck: state.deck,
        discard: state.discard,
        players: takePlayers,
        turnIndex: state.turnIndex,
        lastMove: '${player.displayName} atılan taşı aldı',
      );

    case Okey101MoveType.discard:
      if (!player.drewThisTurn && player.hand.length > 14) {
        throw StateError('Önce taş çekmelisiniz');
      }
      final tileId = move.tileId ?? '';
      final idx = player.hand.indexWhere((t) => t.id == tileId);
      if (idx < 0) throw StateError('Taş elinizde yok');
      final tile = player.hand[idx];
      final newHand = [...player.hand]..removeAt(idx);
      final discardPlayers = [...state.players];
      discardPlayers[playerIndex] = player.copyWith(hand: newHand);
      var next = Okey101GameState(
        hostUserId: state.hostUserId,
        phase: state.phase,
        status: state.status,
        openScoreTarget: state.openScoreTarget,
        maxPlayers: state.maxPlayers,
        minPlayers: state.minPlayers,
        indicator: state.indicator,
        okey: state.okey,
        deck: state.deck,
        discard: [...state.discard, tile],
        players: discardPlayers,
        turnIndex: state.turnIndex,
        lastMove: '${player.displayName} taş attı',
      );
      if (player.opened && newHand.isEmpty) {
        next = Okey101GameState(
          hostUserId: next.hostUserId,
          phase: 'finished',
          status: 'finished',
          openScoreTarget: next.openScoreTarget,
          maxPlayers: next.maxPlayers,
          minPlayers: next.minPlayers,
          indicator: next.indicator,
          okey: next.okey,
          deck: next.deck,
          discard: next.discard,
          players: next.players,
          turnIndex: playerIndex,
          winnerId: userId,
          winnerName: player.displayName,
          lastMove: '${player.displayName} okey attı!',
        );
        return _applyPenalties(next, userId);
      }
      final nextIndex = (state.turnIndex + 1) % state.players.length;
      final resetPlayers = next.players
          .map((p) => p.copyWith(drewThisTurn: false))
          .toList();
      return Okey101GameState(
        hostUserId: next.hostUserId,
        phase: next.phase,
        status: next.status,
        openScoreTarget: next.openScoreTarget,
        maxPlayers: next.maxPlayers,
        minPlayers: next.minPlayers,
        indicator: next.indicator,
        okey: next.okey,
        deck: next.deck,
        discard: next.discard,
        players: resetPlayers,
        turnIndex: nextIndex,
        winnerId: next.winnerId,
        winnerName: next.winnerName,
        lastMove: next.lastMove,
      );

    case Okey101MoveType.open:
      final points = _handPoints(player.hand, okey);
      if (points < state.openScoreTarget) {
        throw StateError('Açmak için en az ${state.openScoreTarget} puan gerekli');
      }
      if (!_hasBasicGroup(player.hand, okey)) {
        throw StateError('Geçerli per/çift yok');
      }
      final openPlayers = [...state.players];
      openPlayers[playerIndex] = player.copyWith(opened: true);
      return Okey101GameState(
        hostUserId: state.hostUserId,
        phase: state.phase,
        status: state.status,
        openScoreTarget: state.openScoreTarget,
        maxPlayers: state.maxPlayers,
        minPlayers: state.minPlayers,
        indicator: state.indicator,
        okey: state.okey,
        deck: state.deck,
        discard: state.discard,
        players: openPlayers,
        turnIndex: state.turnIndex,
        lastMove: '${player.displayName} 101 ile açtı ($points puan)',
      );

    case Okey101MoveType.start:
      return startGame(state, userId);
  }
}

Map<String, dynamic> publicView(Okey101GameState state, String viewerUserId) {
  return {
    'gameType': 'okey101',
    'phase': state.phase,
    'status': state.status,
    'openScoreTarget': state.openScoreTarget,
    'maxPlayers': state.maxPlayers,
    'minPlayers': state.minPlayers,
    'indicator': state.indicator == null
        ? null
        : {
            'id': state.indicator!.id,
            'color': state.indicator!.color.name,
            'value': state.indicator!.value,
            'isFakeJoker': state.indicator!.isFakeJoker,
          },
    'okey': state.okey == null
        ? null
        : {
            'id': state.okey!.id,
            'color': state.okey!.color.name,
            'value': state.okey!.value,
          },
    'deckCount': state.deck.length,
    'discardTop': state.discard.isEmpty
        ? null
        : {
            'id': state.discard.last.id,
            'color': state.discard.last.color.name,
            'value': state.discard.last.value,
            'isFakeJoker': state.discard.last.isFakeJoker,
          },
    'discardCount': state.discard.length,
    'turnUserId': state.players.isEmpty ? null : state.players[state.turnIndex].userId,
    'turnName': state.players.isEmpty ? null : state.players[state.turnIndex].displayName,
    'winnerId': state.winnerId,
    'winnerName': state.winnerName,
    'lastMove': state.lastMove,
    'hostUserId': state.hostUserId,
    'players': state.players.map((p) {
      final isMe = p.userId == viewerUserId;
      return {
        'userId': p.userId,
        'displayName': p.displayName,
        'seat': p.seat,
        'handCount': p.hand.length,
        'opened': p.opened,
        'penalty': p.penalty,
        'connected': p.connected,
        'isMe': isMe,
        'hand': isMe
            ? p.hand
                .map(
                  (t) => {
                    'id': t.id,
                    'color': t.color.name,
                    'value': t.value,
                    'isFakeJoker': t.isFakeJoker,
                  },
                )
                .toList()
            : [],
      };
    }).toList(),
    'myHandPoints': _handPoints(
      state.players
              .where((p) => p.userId == viewerUserId)
              .map((p) => p.hand)
              .firstOrNull ??
          const [],
      state.okey,
    ),
  };
}
